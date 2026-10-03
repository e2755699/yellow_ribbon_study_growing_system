'use strict';
const {onRequest} = require('firebase-functions/v2/https');
const {defineSecret} = require('firebase-functions/params');
const logger = require('firebase-functions/logger');
const {Storage} = require('@google-cloud/storage');
const {GoogleAuth} = require('google-auth-library');
const {Store} = require('./store.cjs');
const ciToken = defineSecret('YR_CI_TOKEN'), appleSecret = defineSecret('YR_APPLE_WEBHOOK_SECRET'), cmToken = defineSecret('YR_CODEMAGIC_TOKEN');
const project = 'test-o9g27r';
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
const {createDispatcher} = require('./dispatch.cjs');
const dispatch = createDispatcher({store, enqueue, cmToken, logger});
const {createHandler} = require('./service.cjs');
exports.releaseNotifier = onRequest({region: 'asia-east1', serviceAccount: `release-notifier@${project}.iam.gserviceaccount.com`, secrets: [ciToken, appleSecret, cmToken], invoker: 'public', memory: '256MiB', cpu: 1, minInstances: 0, maxInstances: 2, timeoutSeconds: 60, concurrency: 10}, createHandler({store, enqueue, dispatch, ciToken, appleSecret, logger}));
