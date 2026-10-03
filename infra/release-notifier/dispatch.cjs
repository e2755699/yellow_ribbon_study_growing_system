'use strict';
const {githubStatus} = require('./ci.cjs');
function createDispatcher({store, enqueue, cmToken, logger, checkRelease, notificationTag, notificationUrl, fetchImpl = fetch}) {
const app = '682ae5ef5970ccc949f53a6c';
return async function dispatch(id, uploadId, kind) {
  const path = `releases/${id}.json`; const current = (await store.read(path)).value;
  if (!current) return;
  if (current.result) {
    if (!current.runId || current.notificationWorkflowState) return;
    const response = await fetchImpl(`https://api.codemagic.io/builds/${current.runId}`, {headers: {'x-auth-token': cmToken.value()}, signal: AbortSignal.timeout(20000)});
    if (!response.ok) throw new Error(`Notification job lookup HTTP ${response.status}`);
    const job = (await response.json()).build;
    if (!['finished','failed','canceled','cancelled','timeout','timed_out'].includes(job.status)) {await enqueue(`${id}-notification-${Date.now()}`,{id},Date.now()+300000); return;}
    // A failed/unknown Apple result deliberately exits 1, but its failure email
    // can publish successfully. Do not mistake that expected exit for mail failure.
    const published = job.buildActions?.some(action => action.name === 'Publishing' && action.status === 'success');
    const expectedFailure = current.result.status !== 'ready' && job.status === 'failed' && published;
    await store.update(path, old => ({...old, notificationWorkflowState: job.status, notificationPublishingSucceeded: Boolean(published)}));
    if (job.status !== 'finished' && !expectedFailure) logger.error('Release verification finished but notification job did not succeed', {releaseId:id,verifierRunId:current.runId,status:job.status});
    return;
  }
  const now = Date.now();
  const sourceRef = {tag: notificationTag};
  if (/^[a-f0-9]{24}$/.test(id) || current.ciProvider === 'github') {
    let build;
    if (current.ciProvider === 'github') build = {status:await githubStatus(fetchImpl,current)};
    else {
      const response = await fetchImpl(`https://api.codemagic.io/builds/${id}`, {headers: {'x-auth-token': cmToken.value()}, signal: AbortSignal.timeout(20000)});
      if (!response.ok) throw new Error(`Codemagic build lookup HTTP ${response.status}`);
      build = (await response.json()).build;
    }
    // The notification implementation is pinned independently of the app source.
    if (['failed','canceled','cancelled','timeout','timed_out'].includes(build.status)) {
      if (current.ciProvider === 'github') {
        current.verifiedResult = {status:'failed',phase:'CI',reason:`CI_${build.status.toUpperCase()}`,appId:current.appId,version:current.version,buildNumber:current.buildNumber,commit:current.commit,releaseId:id,checkedAt:new Date().toISOString()};
        await store.update(path, old => ({...old,verifiedResult:current.verifiedResult}));
      } else {
      await store.update(path, old => old.result ? undefined : {...old, completedAt: new Date().toISOString(), result: {status:'failed', phase:'CI', reason:`CI_${build.status.toUpperCase()}`, appId:old.appId, version:old.version, buildNumber:old.buildNumber}});
      await store.update('active.json', old => old?.id===id ? {id,until:0} : undefined);
      if(build.status!=='failed') logger.error('Release build canceled or timed out', {releaseId:id,status:build.status});
      return;
      }
    }
    if (!current.verifiedResult && !uploadId && build.status !== 'finished' && now < current.deadline) {await enqueue(`${id}-build-${now}`,{id,kind},now+120000); return;}
    if (kind === 'build_status' && build.status === 'finished') return;
  }
  if (current.leaseUntil > now) { await enqueue(`${id}-retry-${current.leaseUntil}`, {id}, current.leaseUntil + 5000); return; }
  if (current.verifierBuildId) {
    const response = await fetchImpl(`https://api.codemagic.io/builds/${current.verifierBuildId}`, {headers: {'x-auth-token': cmToken.value()}, signal: AbortSignal.timeout(20000)});
    if (!response.ok) throw new Error(`Notification job lookup HTTP ${response.status}`);
    const job = (await response.json()).build;
    if (!['finished','failed','canceled','cancelled','timeout','timed_out'].includes(job.status)) {
      await enqueue(`${id}-queued-${now}`, {id}, now + 120000);
      return;
    }
  }
  if ((current.notificationAttempts || 0) >= 3) {
    if (!current.notificationExhausted) {
      logger.error('Release notification launch attempts exhausted', {releaseId:id});
      await store.update(path, old => ({...old, notificationExhausted:true}));
      await store.update('active.json', old => old?.id===id ? {id,until:0} : undefined);
    }
    return;
  }
  // A short launch lease limits duplicate jobs if the POST outcome is unknown.
  let obtained = false;
  await store.update(path, old => {obtained = false; if (!old || old.result || old.leaseUntil > now) return; obtained = true; return {...old, leaseUntil: now + 120000};});
  if (!obtained) return;
  // Enqueue recovery before making the external request, covering crashes / lost responses.
  await enqueue(`${id}-recover-${now}`, {id}, now + 125000);
  if (!current.verifiedResult) {
    const observed = await checkRelease(current, uploadId);
    if (observed.ignored || observed.status === 'pending') {
      const attempt = (current.checkAttempts || 0) + 1;
      const wait = observed.ignored ? 20000 : Math.min(20000 * 2 ** Math.min(attempt - 1, 4), 300000);
      const next = Math.min(now + wait, current.deadline);
      // A queued task is durable before releasing this execution's lease.
      await enqueue(`${id}-observe-${now}`, {id}, Math.max(now + 1000, next));
      await store.update(path, old => ({...old, checkAttempts: attempt, leaseUntil: Math.max(now + 1000, next), lastObservation: observed}));
      return;
    }
    if (!['ready', 'failed', 'unknown'].includes(observed.status) || observed.appId !== current.appId || observed.version !== current.version || observed.buildNumber !== current.buildNumber || observed.commit !== current.commit) throw new Error('Invalid verification identity');
    await store.update(path, old => ({...old, verifiedResult: observed}));
  }
  if (!notificationTag) throw new Error('Missing pinned notification workflow tag');
  await store.update(path, old => ({...old, notificationAttempts:(old.notificationAttempts || 0) + 1}));
  const r = await fetchImpl('https://api.codemagic.io/builds', {method: 'POST', headers: {'x-auth-token': cmToken.value(), 'Content-Type': 'application/json'}, body: JSON.stringify({appId: app, workflowId: 'testflight-verify', ...sourceRef, environment: {variables: {YR_RELEASE_ID: id, YR_SOURCE_COMMIT: current.commit, ...(notificationUrl ? {YR_CI_URL:notificationUrl} : {}), ...(uploadId ? {YR_APPLE_UPLOAD_ID: uploadId} : {})}}}), signal: AbortSignal.timeout(25000)});
  if (!r.ok) throw new Error(`Codemagic verifier launch HTTP ${r.status}`);
  const job = await r.json();
  if (!job.buildId) throw new Error('Codemagic omitted verifier build ID');
  await store.update(path, old => ({...old, verifierBuildId: job.buildId}));
  logger.info('Release verifier dispatched', {releaseId: id, verifierBuildId: job.buildId});
}
}
module.exports = {createDispatcher};
