'use strict';
const crypto = require('node:crypto');
const APP = '6746115397';
const GROUP = '43256c93-cc4f-4453-839f-1eadf6205b97';
const ORIGIN = 'https://api.appstoreconnect.apple.com';
const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
class ApiError extends Error {
  constructor(status, message) { super(message); this.status = status; }
}
function token(env = process.env, now = Math.floor(Date.now() / 1000)) {
  for (const key of ['APP_STORE_CONNECT_ISSUER_ID', 'APP_STORE_CONNECT_KEY_IDENTIFIER', 'APP_STORE_CONNECT_PRIVATE_KEY']) {
    if (!env[key]) throw new Error(`Missing ${key}`);
  }
  const unsigned = [{alg: 'ES256', kid: env.APP_STORE_CONNECT_KEY_IDENTIFIER, typ: 'JWT'},
    {iss: env.APP_STORE_CONNECT_ISSUER_ID, iat: now, exp: now + 300, aud: 'appstoreconnect-v1'}]
    .map(x => Buffer.from(JSON.stringify(x)).toString('base64url')).join('.');
  return unsigned + '.' + crypto.sign('sha256', Buffer.from(unsigned), {
    key: env.APP_STORE_CONNECT_PRIVATE_KEY, dsaEncoding: 'ieee-p1363',
  }).toString('base64url');
}
function client({env = process.env, fetchImpl = fetch, delay = sleep, attempts = 4, timeoutMs = 30000} = {}) {
  return async function api(path) {
    const url = new URL(path, ORIGIN);
    if (url.origin !== ORIGIN) throw new Error('Unexpected API origin');
    for (let attempt = 0; attempt < attempts; attempt++) {
      let response;
      try { response = await fetchImpl(url, {headers: {Authorization: `Bearer ${token(env)}`}, signal: AbortSignal.timeout(timeoutMs)}); }
      catch (error) { if (attempt === attempts - 1) throw new ApiError(0, 'Apple API network timeout'); await delay(2000 * 2 ** attempt); continue; }
      if (response.ok) return response.json();
      if ((response.status === 429 || response.status >= 500) && attempt < attempts - 1) { await delay(2000 * 2 ** attempt); continue; }
      // Do not include request headers or token in error artifacts.
      throw new ApiError(response.status, `Apple API HTTP ${response.status}: ${url.pathname}`);
    }
  };
}
async function all(api, path) {
  const data = []; const seen = new Set();
  while (path) {
    if (seen.has(path) || seen.size > 100) throw new Error('Invalid API pagination');
    seen.add(path); const page = await api(path);
    if (!Array.isArray(page.data)) throw new Error('Unexpected API response');
    data.push(...page.data); path = page.links?.next;
  }
  return data;
}
function identity(version, number) {
  if (!/^\d+\.\d+(?:\.\d+)?$/.test(version) || !/^[1-9]\d*$/.test(String(number))) throw new Error('Invalid version/build number');
  return {appId: APP, version, buildNumber: String(number), groupId: GROUP};
}
async function inspect(api, version, number) {
  const result = {...identity(version, number), checkedAt: new Date().toISOString()};
  const group = (await api(`/v1/betaGroups/${GROUP}`)).data;
  if (group?.attributes?.name !== 'yellowribbon' || !group.attributes.isInternalGroup) throw new Error('Internal group identity mismatch');
  const query = new URLSearchParams({'filter[app]': APP, 'filter[version]': String(number), 'filter[preReleaseVersion.version]': version, limit: '200'});
  const builds = await all(api, `/v1/builds?${query}`);
  if (builds.length > 1) throw new Error('Ambiguous build identity');
  if (!builds.length) {
    const uploads = await all(api, `/v1/apps/${APP}/buildUploads?limit=200`);
    const matching = uploads.filter(x => x.attributes.cfBundleShortVersionString === version && x.attributes.cfBundleVersion === String(number));
    const failed = matching.find(x => x.attributes.state?.state === 'FAILED');
    if (failed) return {...result, status: 'failed', reason: 'APPLE_UPLOAD_FAILED', uploadId: failed.id, errors: failed.attributes.state.errors};
    return {...result, status: 'pending', reason: 'BUILD_NOT_VISIBLE'};
  }
  const build = builds[0], a = build.attributes;
  if (a.version !== String(number)) throw new Error('Build number mismatch');
  Object.assign(result, {buildId: build.id, processingState: a.processingState, expired: a.expired});
  if (a.expired || ['FAILED', 'INVALID'].includes(a.processingState)) return {...result, status: 'failed', reason: a.expired ? 'EXPIRED' : a.processingState};
  if (a.processingState !== 'VALID') return {...result, status: 'pending', reason: 'APPLE_PROCESSING'};
  const detail = (await api(`/v1/builds/${build.id}/buildBetaDetail`)).data.attributes;
  result.internalBuildState = detail.internalBuildState;
  if (['PROCESSING_EXCEPTION', 'EXPIRED', 'MISSING_EXPORT_COMPLIANCE'].includes(detail.internalBuildState)) return {...result, status: 'failed', reason: detail.internalBuildState};
  const members = await all(api, `/v1/betaGroups/${GROUP}/builds?limit=200`);
  result.inGroup = members.some(x => x.id === build.id);
  if (detail.internalBuildState !== 'IN_BETA_TESTING' || !result.inGroup) return {...result, status: 'pending', reason: !result.inGroup ? 'GROUP_NOT_READY' : 'INTERNAL_TESTING_NOT_READY'};
  return {...result, status: 'ready', reason: 'INTERNAL_TESTING_AVAILABLE'};
}
module.exports = {APP, GROUP, ApiError, client, all, inspect, identity, token};
