const {test} = require('node:test');
const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const {APP, GROUP, inspect, client, ApiError} = require('./apple.cjs');
function fixture({processing = 'VALID', internal = 'IN_BETA_TESTING', member = true, expired = false, visible = true, failed = false} = {}) {
  const calls = [];
  return {calls, api: async path => {
    calls.push(path);
    if (path === `/v1/betaGroups/${GROUP}`) return {data: {attributes: {name: 'yellowribbon', isInternalGroup: true}}};
    if (path.startsWith('/v1/builds?')) {
      const q = new URL('https://example.com' + path).searchParams;
      assert.equal(q.get('filter[app]'), APP); assert.equal(q.get('filter[version]'), '12'); assert.equal(q.get('filter[preReleaseVersion.version]'), '1.0.1');
      return {data: visible ? [{id: 'build-12', attributes: {version: '12', processingState: processing, expired}}] : []};
    }
    if (path.endsWith('/buildBetaDetail')) return {data: {attributes: {internalBuildState: internal}}};
    if (path.includes('/buildUploads')) return {data: [{id: 'upload-12', attributes: {cfBundleVersion: '12', cfBundleShortVersionString: '1.0.1', state: {state: failed ? 'FAILED' : 'PROCESSING', errors: []}}}]};
    if (path.includes('/builds?limit')) return {data: [{id: 'unrelated-build'}], links: {next: '/next-page'}};
    if (path === '/next-page') return {data: member ? [{id: 'build-12'}] : []};
    throw Error('Unexpected path ' + path);
  }};
}
test('ready requires exact build, internal state and paginated group membership', async () => {
  const f = fixture(); const r = await inspect(f.api, '1.0.1', '12'); assert.equal(r.status, 'ready'); assert(f.calls.includes('/next-page'));
});
for (const [name, input, status, reason] of [
  ['processing', {processing: 'PROCESSING'}, 'pending', 'APPLE_PROCESSING'],
  ['invalid', {processing: 'INVALID'}, 'failed', 'INVALID'],
  ['expired', {expired: true}, 'failed', 'EXPIRED'],
  ['missing group', {member: false}, 'pending', 'GROUP_NOT_READY'],
  ['external ready does not establish internal readiness', {internal: 'READY_FOR_BETA_TESTING'}, 'pending', 'INTERNAL_TESTING_NOT_READY'],
  ['export compliance', {internal: 'MISSING_EXPORT_COMPLIANCE'}, 'failed', 'MISSING_EXPORT_COMPLIANCE'],
  ['upload failed before build appears', {visible: false, failed: true}, 'failed', 'APPLE_UPLOAD_FAILED'],
  ['upload pending', {visible: false}, 'pending', 'BUILD_NOT_VISIBLE'],
]) test(name, async () => {const r = await inspect(fixture(input).api, '1.0.1', '12'); assert.equal(r.status, status); assert.equal(r.reason, reason);});
test('unauthorized is an API error, never a failed Apple build', async () => {
  await assert.rejects(inspect(async () => {throw new ApiError(401, 'unauthorized');}, '1.0.1', '12'), e => e.status === 401);
});
test('HTTP retry is bounded; 401/403 do not retry', async () => {
  const {privateKey} = crypto.generateKeyPairSync('ec', {namedCurve: 'prime256v1'});
  const env = {APP_STORE_CONNECT_ISSUER_ID: 'issuer', APP_STORE_CONNECT_KEY_IDENTIFIER: 'key', APP_STORE_CONNECT_PRIVATE_KEY: privateKey.export({type: 'pkcs8', format: 'pem'})};
  for (const status of [401,403,429,500]) {
    let count = 0; const api = client({env, delay: async () => {}, fetchImpl: async () => {count++; return {ok: false, status};}});
    await assert.rejects(api('/v1/builds'), e => e.status === status); assert.equal(count, status < 429 ? 1 : 4);
  }
});
test('credentials cannot be forwarded to an unrelated pagination host', async () => {await assert.rejects(client()('https://other.example/'), /origin/);});
