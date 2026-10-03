const {test} = require('node:test'), assert = require('node:assert/strict');
const {poll, message} = require('./poll.cjs');
const {APP, GROUP} = require('./apple.cjs');
const release = {version: '1.0.2', buildNumber: '13', commit: 'a'.repeat(40)};

// Synthetic App Store Connect responses; states advance once per poll.
function fakeApi(states) {
  let call = 0;
  return async path => {
    if (path === `/v1/betaGroups/${GROUP}`) return {data: {attributes: {name: 'yellowribbon', isInternalGroup: true}}};
    const state = states[Math.min(call, states.length - 1)];
    if (path.startsWith('/v1/builds?')) { call++; return state === 'missing' ? {data: []} : {data: [{id: 'b1', attributes: {version: '13', processingState: state, expired: false}}]}; }
    if (path === `/v1/apps/${APP}/buildUploads?limit=200`) return {data: []};
    if (path === '/v1/builds/b1/buildBetaDetail') return {data: {attributes: {internalBuildState: 'IN_BETA_TESTING'}}};
    if (path === `/v1/betaGroups/${GROUP}/builds?limit=200`) return {data: [{id: 'b1'}]};
    throw new Error('unexpected ' + path);
  };
}
const fast = clock => ({intervalMs: 1000, timeoutMs: 5000, now: () => clock.t, delay: async ms => { clock.t += ms; }});

test('polls until Apple reports the build ready in the internal group', async () => {
  const clock = {t: 0};
  const result = await poll(fakeApi(['missing', 'PROCESSING', 'VALID']), release, fast(clock));
  assert.equal(result.status, 'ready');
  assert.equal(result.buildId, 'b1');
  assert.equal(clock.t, 2000);
});
test('stops immediately when Apple marks the build invalid', async () => {
  const result = await poll(fakeApi(['INVALID']), release, fast({t: 0}));
  assert.equal(result.status, 'failed');
  assert.equal(result.reason, 'INVALID');
});
test('reports unknown instead of success when the deadline passes', async () => {
  const result = await poll(fakeApi(['PROCESSING']), release, fast({t: 0}));
  assert.equal(result.status, 'unknown');
  assert.match(result.reason, /^TIMEOUT_APPLE_PROCESSING$/);
});
test('rejects a malformed release identity before calling Apple', async () => {
  await assert.rejects(poll(fakeApi(['VALID']), {version: 'x', buildNumber: '0'}, fast({t: 0})), /Invalid version/);
});
test('notification text names version, build and result', () => {
  const text = message(release, {status: 'ready', reason: 'INTERNAL_TESTING_AVAILABLE', buildId: 'b1', checkedAt: '2026-10-03T00:00:00Z'});
  assert.match(text, /TestFlight 內測可更新\n版本 1\.0\.2 \(13\)/);
});
