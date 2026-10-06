import { test } from 'node:test';
import assert from 'node:assert/strict';
import { build } from 'esbuild';
import { Miniflare, convertV4MiniflareOptions } from 'miniflare';
import { generateKeyPair, exportPKCS8 } from 'jose';

test('workerd completes Firestore, service OAuth and Drive lookup without following redirects', async () => {
  const { privateKey } = await generateKeyPair('RS256', { extractable: true });
  const bundle = await build({
    stdin: { contents: "import {createWorker} from './src/worker.js'; export default createWorker({verify: async () => 'synthetic-teacher'});", resolveDir: process.cwd() },
    bundle: true, write: false, format: 'esm', platform: 'browser',
  });
  let redirectAt;
  const calls = [];
  const mf = new Miniflare(convertV4MiniflareOptions({
    modules: true, compatibilityDate: '2026-10-06', script: bundle.outputFiles[0].text,
    bindings: {
      POC_ENABLED: 'true', FIREBASE_PROJECT_ID: 'demo-yellow-ribbon',
      POC_STUDENT_IDS: '["test-student"]', DRIVE_FOLDER_ID: 'test-folder',
      GOOGLE_SERVICE_ACCOUNT_EMAIL: 'synthetic@example.iam.gserviceaccount.com',
      GOOGLE_SERVICE_ACCOUNT_PRIVATE_KEY: await exportPKCS8(privateKey),
    },
    outboundService: async request => {
      const host = new URL(request.url).hostname;
      calls.push(host);
      if (host === redirectAt) return new Response(null, { status: 302, headers: { location: 'https://must-not-follow.test/' } });
      if (host === 'firestore.googleapis.com') return Response.json({ name: 'projects/demo-yellow-ribbon/databases/(default)/documents/students/test-student' });
      if (host === 'oauth2.googleapis.com') return Response.json({ access_token: 'synthetic-drive-token', expires_in: 3600 });
      if (host === 'www.googleapis.com') return Response.json({ files: [] });
      throw Error('Unexpected outbound host');
    },
  }));
  const request = () => mf.dispatchFetch('http://localhost/v1/students/test-student/uploads/00000000-0000-4000-8000-000000000001', { headers: { authorization: 'Bearer synthetic-token' } });
  try {
    redirectAt = 'oauth2.googleapis.com';
    let response = await request();
    assert.equal(response.status, 503);
    assert.equal((await response.json()).error, 'drive_identity_unavailable');
    assert.deepEqual(calls, ['firestore.googleapis.com', 'oauth2.googleapis.com']);
    calls.length = 0; redirectAt = undefined;
    response = await request();
    assert.equal(response.status, 200);
    assert.equal((await response.json()).status, 'unknown');
    assert.deepEqual(calls, ['firestore.googleapis.com', 'oauth2.googleapis.com', 'www.googleapis.com']);
    for (const [host, code] of [['firestore.googleapis.com', 'authorization_unavailable'], ['www.googleapis.com', 'drive_unavailable']]) {
      redirectAt = host; calls.length = 0;
      response = await request();
      assert.equal(response.status, 503);
      assert.equal((await response.json()).error, code);
      assert.equal(calls.includes('must-not-follow.test'), false);
    }
  } finally { await mf.dispose(); }
});
