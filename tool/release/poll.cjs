'use strict';
// CI-A9: verify a TestFlight upload from GitHub Actions by polling the App Store
// Connect API, replacing the Apple webhook + Cloud Tasks + Cloud Storage path.
// Usage: node tool/release/poll.cjs RELEASE_JSON OUTPUT_DIR
const fs = require('node:fs');
const path = require('node:path');
const {client, inspect, identity} = require('./apple.cjs');
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));

async function poll(api, release, {intervalMs = 60000, timeoutMs = 90 * 60000, now = Date.now, delay = sleep} = {}) {
  const {version, buildNumber} = identity(release.version, release.buildNumber);
  const deadline = now() + timeoutMs;
  let last;
  for (;;) {
    try { last = await inspect(api, version, buildNumber); }
    // Transient API failures are retried until the deadline; identity errors are not.
    catch (error) { if (error.status === undefined || error.status >= 400 && error.status < 500 && error.status !== 429) throw error; last = {status: 'pending', reason: error.message}; }
    if (last.status !== 'pending') return last;
    if (now() + intervalMs > deadline) return {...last, status: 'unknown', reason: `TIMEOUT_${last.reason}`};
    await delay(intervalMs);
  }
}
function message(release, result) {
  const title = result.status === 'ready' ? 'TestFlight 內測可更新' : result.status === 'failed' ? 'TestFlight 發布失敗' : 'TestFlight 尚無法確認完成';
  return `${title}\n版本 ${release.version} (${release.buildNumber})\n${result.reason}\nCommit: ${release.commit || '未知'}\nApple build: ${result.buildId || '尚未取得'}\n檢查時間: ${result.checkedAt}\n`;
}
async function main([releaseFile, outputDir] = process.argv.slice(2)) {
  if (!releaseFile || !outputDir) throw new Error('Usage: poll.cjs RELEASE_JSON OUTPUT_DIR');
  const release = JSON.parse(fs.readFileSync(releaseFile, 'utf8'));
  const result = await poll(client(), release);
  const text = message(release, result);
  fs.mkdirSync(outputDir, {recursive: true});
  fs.writeFileSync(path.join(outputDir, 'result.json'), JSON.stringify({...result, commit: release.commit}, null, 2));
  fs.writeFileSync(path.join(outputDir, 'result.txt'), text);
  console.log(text);
  if (result.status !== 'ready') process.exitCode = 1;
}
module.exports = {poll, message};
if (require.main === module) main().catch(error => { console.error(error.message); process.exitCode = 1; });
