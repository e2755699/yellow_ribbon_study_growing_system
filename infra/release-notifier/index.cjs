'use strict';
const {onRequest} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const {Storage} = require('@google-cloud/storage');
const {GoogleAuth} = require('google-auth-library');
const {Store} = require('./store.cjs');
const {equal, appleSignature, safeId, validRelease, event} = require('./core.cjs');
const ciToken = defineSecret('YR_CI_TOKEN'), appleSecret = defineSecret('YR_APPLE_WEBHOOK_SECRET'), cmToken = defineSecret('YR_CODEMAGIC_TOKEN');
const project = 'test-o9g27r', app = '682ae5ef5970ccc949f53a6c';
const origin = `https://asia-east1-${project}.cloudfunctions.net/releaseNotifier`;
const queue = `projects/${project}/locations/asia-east1/queues/release-ci`;
const store = new Store(new Storage().bucket(`${project}-release-ci`));
const auth = new GoogleAuth({scopes: ['https://www.googleapis.com/auth/cloud-platform']});
async function enqueue(name, payload, when = Date.now()) {
  const token = await auth.getAccessToken();
  const r = await fetch(`https://cloudtasks.googleapis.com/v2/${queue}/tasks`, {
    method: 'POST', headers: {Authorization: `Bearer ${token}`, 'Content-Type': 'application/json'},
    body: JSON.stringify({task: {name: `${queue}/tasks/${name}`, scheduleTime: new Date(when).toISOString(), httpRequest: {url: origin + '/dispatch', httpMethod: 'POST', headers: {Authorization: `Bearer ${ciToken.value()}`, 'Content-Type': 'application/json'}, body: Buffer.from(JSON.stringify(payload)).toString('base64')}}}), signal: AbortSignal.timeout(20000),
  });
  if (!r.ok && r.status !== 409) throw new Error(`Task scheduling HTTP ${r.status}`);
}
async function dispatch(id, uploadId, kind) {
  const path = `releases/${id}.json`; const current = (await store.read(path)).value;
  if (!current || current.result) return;
  const now = Date.now();
  if (/^[a-f0-9]{24}$/.test(id)) {
    const response = await fetch(`https://api.codemagic.io/builds/${id}`, {headers: {'x-auth-token': cmToken.value()}, signal: AbortSignal.timeout(20000)});
    if (!response.ok) throw new Error(`Codemagic build lookup HTTP ${response.status}`);
    const build = (await response.json()).build;
    if (['failed','canceled','cancelled','timeout','timed_out'].includes(build.status)) {
      await store.update(path, old => old.result ? undefined : {...old, completedAt: new Date().toISOString(), result: {status:'failed', phase:'CI', reason:`CI_${build.status.toUpperCase()}`, appId:old.appId, version:old.version, buildNumber:old.buildNumber}});
      await store.update('active.json', old => old?.id===id ? {id,until:0} : undefined);
      if(build.status!=='failed') logger.error('Release build canceled or timed out', {releaseId:id,status:build.status});
      return;
    }
    if (!uploadId && build.status !== 'finished' && now < current.deadline) {await enqueue(`${id}-build-${now}`,{id,kind},now+120000); return;}
    if (kind === 'build_status' && build.status === 'finished') return;
  }
  if (current.leaseUntil > now) { await enqueue(`${id}-retry-${current.leaseUntil}`, {id}, current.leaseUntil + 5000); return; }
  // A short launch lease limits duplicate jobs if the POST outcome is unknown.
  let obtained = false;
  await store.update(path, old => {obtained = false; if (!old || old.result || old.leaseUntil > now) return; obtained = true; return {...old, leaseUntil: now + 120000};});
  if (!obtained) return;
  // Enqueue recovery before making the external request, covering crashes / lost responses.
  await enqueue(`${id}-recover-${now}`, {id}, now + 25 * 60000);
  const r = await fetch('https://api.codemagic.io/builds', {method: 'POST', headers: {'x-auth-token': cmToken.value(), 'Content-Type': 'application/json'}, body: JSON.stringify({appId: app, workflowId: 'testflight-verify', branch: current.branch, environment: {variables: {YR_RELEASE_ID: id, YR_SOURCE_COMMIT: current.commit, ...(uploadId ? {YR_APPLE_UPLOAD_ID: uploadId} : {})}}}), signal: AbortSignal.timeout(25000)});
  if (!r.ok) throw new Error(`Codemagic verifier launch HTTP ${r.status}`);
  const job = await r.json();
  if (!job.buildId) throw new Error('Codemagic omitted verifier build ID');
  await store.update(path, old => ({...old, verifierBuildId: job.buildId}));
  logger.info('Release verifier dispatched', {releaseId: id, verifierBuildId: job.buildId});
}
const {createHandler} = require('./service.cjs');
exports.releaseNotifier = onRequest({region: 'asia-east1', serviceAccount: `release-notifier@${project}.iam.gserviceaccount.com`, secrets: [ciToken, appleSecret, cmToken], invoker: 'public', memory: '256MiB', cpu: 1, minInstances: 0, maxInstances: 2, timeoutSeconds: 60, concurrency: 10}, createHandler({store, enqueue, dispatch, ciToken, appleSecret, logger}));
