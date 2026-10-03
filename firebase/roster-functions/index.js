'use strict';
const {initializeApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const functions = require('firebase-functions/v1');
const { createRosterService, DomainError } = require('./roster-service.cjs');
initializeApp();
const service = createRosterService(getFirestore());
exports.applyDueMemberships = functions.region('asia-east1')
  .runWith({timeoutSeconds:540,memory:'256MB'})
  .pubsub.schedule('0 0 * * *').timeZone('Asia/Taipei')
  .onRun(async()=>{await service.applyDueMemberships();});
exports.rosterCommand = functions.region('asia-east1')
  .runWith({maxInstances: 3, timeoutSeconds: 60, memory: '256MB'})
  .https.onCall(async (data, context) => {
    if (!context.auth) throw new functions.https.HttpsError('unauthenticated', '請先登入');
    try {
      return await service.execute(context.auth.uid, data);
    } catch (error) {
      if (error instanceof DomainError) {
        throw new functions.https.HttpsError(error.code, error.message, error.details);
      }
      // Do not log request bodies containing student information.
      functions.logger.error('roster-command-failed', {code: error.code || 'internal'});
      throw new functions.https.HttpsError('internal', '儲存尚未確認，請保留草稿後重試');
    }
  });
