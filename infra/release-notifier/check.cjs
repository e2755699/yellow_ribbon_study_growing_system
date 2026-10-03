'use strict';
const {inspect, identity} = require('./apple.cjs');
// One observation per Cloud Task. Waiting belongs to the queue, never a runner.
async function checkRelease(api, release, uploadId, now = Date.now()) {
  let result;
  try {
    if (uploadId) {
      const upload = (await api('/v1/buildUploads/' + encodeURIComponent(uploadId))).data;
      if (upload?.attributes?.cfBundleShortVersionString !== release.version ||
          upload.attributes.cfBundleVersion !== release.buildNumber) return {ignored: true};
    }
    result = await inspect(api, release.version, release.buildNumber);
  } catch (e) {
    result = {...identity(release.version, release.buildNumber),
      status: e.status === 401 || e.status === 403 ? 'unknown' : 'pending',
      reason: e.status === 401 || e.status === 403 ? 'APPLE_AUTHORIZATION_FAILED' : 'VERIFICATION_ERROR'};
  }
  if (result.status === 'pending' && now >= release.deadline) {
    result = {...result, status: 'unknown', reason: 'VERIFICATION_TIMEOUT', lastObservedReason: result.reason};
  }
  return {...result, commit: release.commit, releaseId: release.id, checkedAt: new Date(now).toISOString()};
}
module.exports = {checkRelease};
