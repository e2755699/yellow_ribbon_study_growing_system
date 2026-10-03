'use strict';
function createDispatcher({store, enqueue, cmToken, logger, fetchImpl = fetch}) {
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
  let sourceRef = {branch: current.branch};
  if (/^[a-f0-9]{24}$/.test(id)) {
    const response = await fetchImpl(`https://api.codemagic.io/builds/${id}`, {headers: {'x-auth-token': cmToken.value()}, signal: AbortSignal.timeout(20000)});
    if (!response.ok) throw new Error(`Codemagic build lookup HTTP ${response.status}`);
    const build = (await response.json()).build;
    // Tag-triggered jobs report the default branch as CM_BRANCH. Preserve the
    // actual tag so verification always finds the workflow at the release ref.
    if (typeof build.tag === 'string' && build.tag) sourceRef = {tag: build.tag};
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
  const r = await fetchImpl('https://api.codemagic.io/builds', {method: 'POST', headers: {'x-auth-token': cmToken.value(), 'Content-Type': 'application/json'}, body: JSON.stringify({appId: app, workflowId: 'testflight-verify', ...sourceRef, environment: {variables: {YR_RELEASE_ID: id, YR_SOURCE_COMMIT: current.commit, ...(uploadId ? {YR_APPLE_UPLOAD_ID: uploadId} : {})}}}), signal: AbortSignal.timeout(25000)});
  if (!r.ok) throw new Error(`Codemagic verifier launch HTTP ${r.status}`);
  const job = await r.json();
  if (!job.buildId) throw new Error('Codemagic omitted verifier build ID');
  await store.update(path, old => ({...old, verifierBuildId: job.buildId}));
  logger.info('Release verifier dispatched', {releaseId: id, verifierBuildId: job.buildId});
}
}
module.exports = {createDispatcher};
