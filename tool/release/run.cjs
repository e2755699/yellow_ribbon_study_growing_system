'use strict';
const fs = require('node:fs');
const {execFileSync} = require('node:child_process');
const {APP, GROUP, client, all, inspect, identity} = require('./apple.cjs');
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
async function hook(route, data) {
  if (!process.env.YR_CI_URL || !process.env.YR_CI_TOKEN) throw new Error('Missing notification service configuration');
  const url = new URL(route, process.env.YR_CI_URL + '/');
  const base = new URL(process.env.YR_CI_URL);
  if (url.origin !== base.origin) throw new Error('Unexpected notification destination');
  for (let attempt = 0; attempt < 4; attempt++) {
    let r;
    try { r = await fetch(url, {method: 'POST', headers: {Authorization: `Bearer ${process.env.YR_CI_TOKEN}`, 'Content-Type': 'application/json'}, body: JSON.stringify(data), signal: AbortSignal.timeout(30000)}); }
    catch (e) { if (attempt === 3) throw new Error('Notification service network failure'); await sleep(2000 * 2 ** attempt); continue; }
    if (r.ok) return r.json();
    if (r.status >= 500 && attempt < 3) {await sleep(2000 * 2 ** attempt); continue;}
    throw new Error(`Notification service ${route}: HTTP ${r.status}`);
  }
}
function normalized(v) { return v.split('.').map(Number).concat([0,0]).slice(0,3); }
function compare(a,b) { const x=normalized(a), y=normalized(b); for(let i=0;i<3;i++) if(x[i]!==y[i]) return x[i]-y[i]; return 0; }
function openVersion(desired, published) {
  const newest = published.sort(compare).at(-1);
  if (!newest || compare(desired,newest)>0) return desired;
  const n=normalized(newest); n[2]++; return n.join('.');
}
async function preflight(api) {
  const group = (await api(`/v1/betaGroups/${GROUP}`)).data.attributes;
  if (group.name !== 'yellowribbon' || !group.isInternalGroup || !group.hasAccessToAllBuilds) throw new Error('Expected auto-distributing internal group');
  const match = fs.readFileSync('pubspec.yaml','utf8').match(/^version:\s*([\d.]+)\+(\d+)\s*$/m);
  if (!match) throw new Error('Missing pubspec version');
  const released = await all(api, `/v1/apps/${APP}/appStoreVersions?limit=200`);
  const published = released.filter(v => ['READY_FOR_DISTRIBUTION','PROCESSING_FOR_DISTRIBUTION'].includes(v.attributes.appVersionState) || ['READY_FOR_SALE','PENDING_APPLE_RELEASE','PROCESSING_FOR_APP_STORE'].includes(v.attributes.appStoreState)).map(v=>v.attributes.versionString);
  const version = openVersion(match[1], published);
  const uploads = await all(api, `/v1/apps/${APP}/buildUploads?limit=200`);
  const number = String(Math.max(Number(match[2]), ...uploads.map(b=>Number(b.attributes.cfBundleVersion)).filter(Number.isSafeInteger)) + 1);
  const id = process.env.CM_BUILD_ID;
  if (!id) throw new Error('Run release inside Codemagic');
  const commit = execFileSync('git',['rev-parse','HEAD'],{encoding:'utf8'}).trim();
  const release = {...identity(version,number), id, commit, branch: process.env.CM_BRANCH || 'codex/student-roster-integrity'};
  await hook('register',release);
  fs.writeFileSync('release.json',JSON.stringify(release,null,2));
  if (!process.env.CM_ENV) throw new Error('Missing Codemagic environment file');
  fs.appendFileSync(process.env.CM_ENV,`\nYR_RELEASE_VERSION=${version}\nYR_RELEASE_NUMBER=${number}\n`);
  console.log(JSON.stringify({event:'release_registered',...release}));
}
async function verify(api) {
  const id = process.env.YR_RELEASE_ID, runId = process.env.CM_BUILD_ID;
  const release = await hook('release',{id});
  if (!release) throw new Error('Release record not found');
  if (process.env.YR_APPLE_UPLOAD_ID) {
    const upload = (await api('/v1/buildUploads/'+encodeURIComponent(process.env.YR_APPLE_UPLOAD_ID))).data;
    if (upload.attributes.cfBundleShortVersionString !== release.version || upload.attributes.cfBundleVersion !== release.buildNumber) {console.log('Ignored upload event for another release');return;}
  }
  const claim = await hook('claim',{id,runId});
  if (!claim.claimed) {console.log('Another verifier owns this release, or result already recorded');return;}
  let result;
  // Webhook is the trigger. Only bounded consistency rechecks follow it.
  const delays = [0, 20000, 60000, 120000, 240000, 480000];
  for (const ms of delays) {
    if (ms) await sleep(ms);
    try { result = await inspect(api, release.version, release.buildNumber); }
    catch (e) {result = {...identity(release.version,release.buildNumber), status:'unknown', reason:e.status===401||e.status===403?'APPLE_AUTHORIZATION_FAILED':'VERIFICATION_ERROR', detail:e.message};}
    console.log(JSON.stringify(result));
    if (result.status !== 'pending' || Date.now()>release.deadline) break;
  }
  if (result.status === 'pending') result = {...result,status:'unknown',reason:'VERIFICATION_TIMEOUT',lastObservedReason:result.reason};
  Object.assign(result,{commit:release.commit,releaseId:id,verifierRunId:runId,checkedAt:new Date().toISOString()});
  const finished = await hook('finish',{id,runId,result});
  if (!finished.notify) {console.log('Result already recorded; no duplicate notification');return;}
  fs.mkdirSync('release-result',{recursive:true});
  fs.writeFileSync('release-result/result.json',JSON.stringify(result,null,2));
  const title = result.status === 'ready' ? 'TestFlight 內測可更新' : result.status === 'failed' ? 'TestFlight 發布失敗' : 'TestFlight 尚無法確認完成';
  const message = `${title}\n版本 ${release.version} (${release.buildNumber})\n${result.reason}\nCommit: ${release.commit}\nApple build: ${result.buildId||'尚未取得'}\n檢查時間: ${result.checkedAt}\n`;
  fs.writeFileSync('release_notes.txt',message); fs.writeFileSync('release-result/result.txt',message);
  console.log(message);
  if (result.status !== 'ready') process.exitCode=1;
}
async function main() {
  const mode=process.argv[2], api=client();
  if (mode==='preflight') return preflight(api);
  if (mode==='verify') return verify(api);
  if (mode==='inspect') {console.log(JSON.stringify(await inspect(api,process.argv[3],process.argv[4]),null,2));return;}
  throw new Error('Expected preflight, verify or inspect');
}
module.exports={openVersion,hook};
if(require.main===module)main().catch(e=>{console.error(e.message);process.exitCode=1;});
