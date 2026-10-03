'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const crypto = require('node:crypto');
const {spawnSync} = require('node:child_process');

// Execute the real CLI. Only network and time are replaced; no live credentials,
// Apple changes, cloud jobs, or email are involved in these failure-path tests.
const preload = `
const fs = require('node:fs');
const mode = process.env.TEST_MODE;
let now = 1000000, inspections = 0;
Date.now = () => now;
global.setTimeout = (callback, ms) => { now += ms; callback(); return 0; };
const release = {id:'release-test',appId:'6746115397',version:'1.0.1',buildNumber:'12',commit:'b'.repeat(40),deadline:mode==='deadline'?now-1:now+90*60000};
if (mode!=='missing') release.verifiedResult = {...release,releaseId:release.id,checkedAt:new Date(now).toISOString(),
  status:mode==='invalid'?'failed':mode==='timeout'||mode==='unauthorized'?'unknown':mode==='pending'?'pending':'ready',
  reason:mode==='invalid'?'INVALID':mode==='timeout'?'VERIFICATION_TIMEOUT':mode==='unauthorized'?'APPLE_AUTHORIZATION_FAILED':'INTERNAL_TESTING_AVAILABLE',buildId:'build-12'};
if (mode==='wrong') release.verifiedResult.buildNumber='99';
const response = (data, status=200) => ({ok:status===200,status,json:async()=>data});
global.fetch = async (url, options={}) => {
  const p = new URL(url).pathname;
  if (p.endsWith('/release')) return response(release);
  if (p.endsWith('/claim')) return response({claimed:mode!=='duplicate'});
  if (p.endsWith('/finish')) {
    fs.writeFileSync('finished.json',options.body);
    return response({notify:true});
  }
  if (mode==='unauthorized') return response({},401);
  if (p==='/v1/betaGroups/43256c93-cc4f-4453-839f-1eadf6205b97') return response({data:{attributes:{name:'yellowribbon',isInternalGroup:true}}});
  if (p==='/v1/builds') {
    inspections++;
    fs.writeFileSync('inspections.txt',String(inspections));
    const state=mode==='invalid'?'INVALID':mode==='ready'||(mode==='eventual'&&inspections===3)?'VALID':'PROCESSING';
    return response({data:[{id:'build-12',attributes:{version:'12',processingState:state,expired:false}}]});
  }
  if (p.endsWith('/buildBetaDetail')) return response({data:{attributes:{internalBuildState:'IN_BETA_TESTING'}}});
  if (p.endsWith('/builds')) return response({data:[{id:'build-12'}]});
  throw new Error('Unexpected fixture request: '+p);
};
`;
function run(mode) {
  const cwd = fs.mkdtempSync(path.join(os.tmpdir(), 'yr-verifier-test-'));
  try {
    fs.writeFileSync(path.join(cwd,'network.cjs'),preload);
    const {privateKey} = crypto.generateKeyPairSync('ec',{namedCurve:'prime256v1'});
    const env = {...process.env,TEST_MODE:mode,YR_CI_URL:'https://ci.example/releaseNotifier',YR_CI_TOKEN:'synthetic-secret',YR_RELEASE_ID:'release-test',CM_BUILD_ID:'verifier-test',YR_SOURCE_COMMIT:'b'.repeat(40),APP_STORE_CONNECT_ISSUER_ID:'synthetic-issuer',APP_STORE_CONNECT_KEY_IDENTIFIER:'synthetic-key',APP_STORE_CONNECT_PRIVATE_KEY:privateKey.export({type:'pkcs8',format:'pem'})};
    delete env.YR_APPLE_UPLOAD_ID;
    const child = spawnSync(process.execPath,['--require',path.join(cwd,'network.cjs'),path.join(__dirname,'run.cjs'),'verify'],{cwd,env,encoding:'utf8',timeout:10000});
    assert.ifError(child.error);
    const read = name => fs.existsSync(path.join(cwd,name)) ? fs.readFileSync(path.join(cwd,name),'utf8') : null;
    const json = read('release-result/result.json');
    assert(!String(child.stdout+child.stderr+json).includes('synthetic-secret'));
    assert(!String(child.stdout+child.stderr+json).includes('PRIVATE KEY'));
    return {exit:child.status,result:json&&JSON.parse(json),count:Number(read('inspections.txt')),finished:read('finished.json'),notes:read('release_notes.txt')};
  } finally {
    const resolved = path.resolve(cwd), temporaryRoot = path.resolve(os.tmpdir());
    assert.equal(path.dirname(resolved),temporaryRoot);
    assert(path.basename(resolved).startsWith('yr-verifier-test-'));
    fs.rmSync(resolved,{recursive:true,force:true});
  }
}
test('CLI reads verified exact result with zero Apple calls and creates notification artifact',()=>{
  const r=run('ready');assert.equal(r.exit,0);assert.equal(r.count,0);assert.equal(r.result.status,'ready');assert.match(r.notes,/TestFlight 內測可更新/);assert.equal(JSON.parse(r.finished).result.buildId,'build-12');
});
for (const [mode,status,reason] of [['timeout','unknown','VERIFICATION_TIMEOUT'],['unauthorized','unknown','APPLE_AUTHORIZATION_FAILED'],['invalid','failed','INVALID']]) {
  test('CLI sends stored '+mode+' without waiting or rechecking Apple',()=>{const r=run(mode);assert.equal(r.exit,1);assert.equal(r.count,0);assert.equal(r.result.status,status);assert.equal(r.result.reason,reason);assert(r.finished);assert(r.notes);});
}
for (const mode of ['missing','pending','wrong']) test('CLI refuses '+mode+' verification record',()=>{
  const r=run(mode);assert.equal(r.exit,1);assert.equal(r.count,0);assert.equal(r.finished,null);assert.equal(r.notes,null);
});
test('CLI duplicate notifier cannot overwrite result or create notification artifacts',()=>{const r=run('duplicate');assert.equal(r.exit,0);assert.equal(r.count,0);assert.equal(r.result,null);assert.equal(r.finished,null);assert.equal(r.notes,null);});
