import { test } from 'node:test';
import assert from 'node:assert/strict';
import { generateKeyPair, exportJWK, exportPKCS8, jwtVerify, SignJWT } from 'jose';
import { createWorker } from '../src/worker.js';
import { createFirebaseVerifier, createDriveTokenProvider } from '../src/auth.js';

const project = 'demo-yellow-ribbon';
const keys = await generateKeyPair('RS256', { extractable: true });
const jwk = { ...await exportJWK(keys.publicKey), kid: 'test-key', alg: 'RS256' };
const env = {
  POC_ENABLED: 'true', FIREBASE_PROJECT_ID: project,
  DRIVE_FOLDER_ID: 'test-folder', POC_STUDENT_IDS: '["test-student"]',
  GOOGLE_SERVICE_ACCOUNT_EMAIL: 'poc@example.iam.gserviceaccount.com',
  GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY: 'injected-test-key',
};
const operation = '00000000-0000-4000-8000-000000000001';
const png = Uint8Array.from([137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3]);
async function token(overrides = {}, signingKey = keys.privateKey) {
  const now = Math.floor(Date.now() / 1000);
  return new SignJWT({ auth_time: now, ...overrides })
    .setProtectedHeader({ alg: 'RS256', kid: 'test-key' })
    .setSubject(overrides.sub ?? 'teacher').setIssuer(overrides.iss ?? `https://securetoken.google.com/${project}`)
    .setAudience(overrides.aud ?? project).setIssuedAt(overrides.iat ?? now)
    .setExpirationTime(overrides.exp ?? now + 3600).sign(signingKey);
}
function fixture({ firestore = 200, metadata = {}, uploadStatus = 200, throwUpload = false, matches = [] } = {}) {
  const calls = [];
  const fetcher = async (url, options = {}) => {
    url = String(url);
    calls.push({ url, options });
    if (url.includes('/service_accounts/v1/jwk/')) return Response.json({ keys: [jwk] });
    if (url.startsWith('https://firestore.googleapis.com/')) return Response.json({ name: `projects/${project}/databases/(default)/documents/students/test-student` }, { status: firestore });
    if (url.includes('/upload/')) {
      if (throwUpload) throw Error('network lost with sensitive upstream data');
      const body = await new Response(options.body).arrayBuffer();
      calls.at(-1).uploaded = new Uint8Array(body);
      return Response.json({ id: 'new-file', mimeType: 'image/png', size: String(png.length) }, { status: uploadStatus });
    }
    if (url.includes('alt=media')) return new Response(png, { headers: { 'content-type': 'image/png' } });
    if (url.includes('/drive/v3/files?')) return Response.json({ files: matches });
    return Response.json({ id: 'file-1', parents: ['test-folder'], mimeType: 'image/png', size: String(png.length),
      appProperties: { app: 'yellow-ribbon-drive-poc-v1', studentId: 'test-student', operationId: operation }, ...metadata });
  };
  const worker = createWorker({ fetcher, driveToken: async () => 'drive-secret', verify: createFirebaseVerifier(fetcher) });
  return { calls, worker, request: async (path = '/v1/students/test-student/files/file-1', options = {}, config = env) =>
    worker.fetch(new Request(`https://worker.test${path}`, { ...options, headers: { authorization: `Bearer ${await token()}`, ...options.headers } }), config) };
}
test('health works without credentials; data requires bearer and explicit enablement', async () => {
  const f = fixture();
  assert.equal((await f.worker.fetch(new Request('https://worker.test/health'), {})).status, 200);
  assert.equal((await f.worker.fetch(new Request('https://worker.test/v1/students/test-student/files/file-1'), env)).status, 401);
  assert.equal((await f.request(undefined, {}, { ...env, POC_ENABLED: 'false' })).status, 503);
  assert.equal(f.calls.length, 0);
});
test('forged, expired, future auth time, wrong audience/issuer and empty subject never reach Firestore or Drive', async () => {
  const other = await generateKeyPair('RS256');
  for (const bad of [await token({}, other.privateKey), await token({ exp: 1 }), await token({ aud: 'other' }),
    await token({ iss: 'https://attacker.test' }), await token({ sub: '' }), await token({ auth_time: 9999999999 })]) {
    const f = fixture();
    assert.equal((await f.request(undefined, { headers: { authorization: `Bearer ${bad}` } })).status, 401);
    assert.equal(f.calls.some(c => !c.url.includes('/jwk/')), false);
  }
});
test('test student allowlist denies before network calls', async () => {
  const f = fixture();
  assert.equal((await f.request('/v1/students/real-student/files/file-1')).status, 403);
  assert.equal(f.calls.length, 0);
});
test('Firestore uses teacher token on every request; upstream errors never grant access', async () => {
  for (const [upstream, expected] of [[403, 403], [404, 404], [401, 401], [500, 503], [429, 503]]) {
    const f = fixture({ firestore: upstream });
    assert.equal((await f.request()).status, expected);
    assert.equal(f.calls.some(c => c.url.includes('/drive/')), false);
    assert.match(f.calls.find(c => c.url.includes('firestore')).options.headers.authorization, /^Bearer ey/);
  }
  const f = fixture();
  await f.request(); await f.request();
  assert.equal(f.calls.filter(c => c.url.includes('firestore')).length, 2);
});
test('folder, student and application markers all bind access; trashed files rejected', async () => {
  for (const metadata of [{ parents: ['other-folder'] }, { trashed: true }, { appProperties: {} },
    { appProperties: { app: 'yellow-ribbon-drive-poc-v1', studentId: 'other-student' } }]) {
    const f = fixture({ metadata });
    assert.equal((await f.request()).status, 404);
    assert.equal(f.calls.some(c => c.url.includes('alt=media')), false);
  }
});
test('download streams bytes with no cache and never exposes service token', async () => {
  const f = fixture(); const response = await f.request();
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('cache-control'), 'private, no-store');
  assert.equal(response.headers.get('x-content-type-options'), 'nosniff');
  assert.deepEqual(new Uint8Array(await response.arrayBuffer()), png);
});
function upload(body = png, headers = {}) {
  return { method: 'POST', body, headers: { 'content-type': 'image/png', 'content-length': String(body.length),
    'x-file-name': encodeURIComponent('測試圖片.png'), 'x-upload-id': operation, ...headers } };
}
test('upload validates MIME, magic, length and operation id before writing', async () => {
  for (const options of [upload(png, { 'content-type': 'text/html' }), upload(new Uint8Array(11)),
    upload(png, { 'content-length': '10485761' }), upload(png, { 'content-length': '' }),
    upload(png, { 'x-upload-id': '' })]) {
    const f = fixture();
    assert.ok((await f.request('/v1/students/test-student/files', options)).status >= 400);
    assert.equal(f.calls.some(c => c.url.includes('/upload/')), false);
  }
});
test('upload fixes parent and labels, preserves bytes, returns file reference only', async () => {
  const f = fixture(); const response = await f.request('/v1/students/test-student/files', upload());
  assert.equal(response.status, 201);
  assert.deepEqual(await response.json(), { provider: 'googleDrive', fileId: 'new-file', operationId: operation });
  const sent = new TextDecoder().decode(f.calls.find(c => c.uploaded).uploaded);
  assert.match(sent, /"parents":\["test-folder"\]/);
  assert.match(sent, /"studentId":"test-student"/);
});
test('network loss and Drive 5xx preserve unknown upload outcome with no blind retry', async () => {
  for (const options of [{ throwUpload: true }, { uploadStatus: 500 }]) {
    const f = fixture(options); const response = await f.request('/v1/students/test-student/files', upload());
    assert.equal(response.status, 503);
    assert.deepEqual(await response.json(), { error: 'upload_outcome_unknown', operationId: operation });
    assert.equal(f.calls.filter(c => c.url.includes('/upload/')).length, 1);
  }
});
test('recovery with no match reports unknown, never safe-to-retry or failed', async () => {
  const f = fixture(); const response = await f.request(`/v1/students/test-student/uploads/${operation}`);
  assert.deepEqual(await response.json(), { operationId: operation, status: 'unknown', fileIds: [] });
});
test('service tokens are deduplicated, reused then refreshed before expiry', async () => {
  let clock = Date.now(), calls = 0;
  const config = { ...env, GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY: await exportPKCS8(keys.privateKey) };
  const getToken = createDriveTokenProvider(async (url, options) => {
    assert.equal(url, 'https://oauth2.googleapis.com/token');
    const { payload } = await jwtVerify(options.body.get('assertion'), keys.publicKey);
    assert.equal(payload.iss, config.GOOGLE_SERVICE_ACCOUNT_EMAIL);
    assert.equal(payload.scope, 'https://www.googleapis.com/auth/drive');
    assert.equal(payload.sub, undefined); // No domain-wide delegation / user impersonation.
    calls++;
    return Response.json({ access_token: `private-${calls}`, expires_in: 3600 });
  }, () => clock);
  assert.deepEqual(await Promise.all([getToken(config), getToken(config)]), ['private-1', 'private-1']);
  assert.equal(await getToken(config), 'private-1');
  clock += 3541000;
  assert.equal(await getToken(config), 'private-2');
  assert.equal(calls, 2);
});
test('service token failures are sanitized and not cached', async () => {
  let calls = 0;
  const config = { ...env, GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY: await exportPKCS8(keys.privateKey) };
  const getToken = createDriveTokenProvider(async () => {
    calls++; return Response.json({ error: 'sensitive response' }, { status: 403 });
  });
  for (let i = 0; i < 2; i++) await assert.rejects(getToken(config), error => error.code === 'drive_identity_unavailable');
  assert.equal(calls, 2);
});
test('streamed upload consumes split magic bytes and rejects truncated/oversized streams', async () => {
  for (const declared of [png.length, png.length - 1, png.length + 1]) {
    const f = fixture();
    let offset = 0;
    const body = new ReadableStream({ pull(controller) {
      if (offset === png.length) { controller.close(); return; }
      controller.enqueue(png.slice(offset, ++offset));
    } });
    const options = { ...upload(png, { 'content-length': String(declared) }), body, duplex: 'half' };
    const response = await f.request('/v1/students/test-student/files', options);
    assert.equal(response.status, declared === png.length ? 201 : 503);
    if (declared !== png.length) assert.equal((await response.json()).error, 'upload_outcome_unknown');
  }
});
test('missing config fails closed and unsupported routes never access Google', async () => {
  for (const missing of ['GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY', 'GOOGLE_SERVICE_ACCOUNT_EMAIL', 'DRIVE_FOLDER_ID', 'POC_STUDENT_IDS']) {
    const f = fixture();
    assert.equal((await f.request(undefined, {}, { ...env, [missing]: '' })).status, 503);
    assert.equal(f.calls.length, 0);
  }
  const f = fixture();
  assert.equal((await f.request('/v1/students/test-student/files/file-1', { method: 'DELETE' })).status, 405);
  assert.equal((await f.request('/v1/anything')).status, 404);
  assert.equal(f.calls.length, 0);
});
test('unknown signing-key infrastructure outage is 503, not loss of permission', async () => {
  const verify = createFirebaseVerifier(async () => { throw Error('network unavailable'); });
  await assert.rejects(verify(await token(), project), error => error.status === 503);
});
