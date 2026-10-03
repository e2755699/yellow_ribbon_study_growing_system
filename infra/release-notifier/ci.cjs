'use strict';
const REPOSITORY = 'e2755699/yellow_ribbon_study_growing_system';
function githubIdentity(env) {
  if (env.GITHUB_REPOSITORY !== REPOSITORY || !/^\d+$/.test(env.GITHUB_RUN_ID || '') || !/^[1-9]\d*$/.test(env.GITHUB_RUN_ATTEMPT || '') || !/^[a-f0-9]{40}$/.test(env.GITHUB_SHA || '')) throw new Error('Invalid GitHub workflow identity');
  return {id:`gh-${env.GITHUB_RUN_ID}-${env.GITHUB_RUN_ATTEMPT}`,ciProvider:'github',ciRunId:env.GITHUB_RUN_ID,ciAttempt:env.GITHUB_RUN_ATTEMPT,ciCommit:env.GITHUB_SHA};
}
async function githubRun(fetchImpl, runId, attempt) {
  if (!/^\d+$/.test(runId || '') || !/^[1-9]\d*$/.test(attempt || '')) throw new Error('Invalid GitHub run');
  const r = await fetchImpl(`https://api.github.com/repos/${REPOSITORY}/actions/runs/${runId}/attempts/${attempt}`, {headers:{Accept:'application/vnd.github+json','User-Agent':'yellow-ribbon-release-notifier','X-GitHub-Api-Version':'2022-11-28'},signal:AbortSignal.timeout(15000)});
  if (!r.ok) throw new Error(`GitHub run lookup HTTP ${r.status}`);
  const run = await r.json();
  if (String(run.id) !== runId || String(run.run_attempt) !== attempt || run.repository?.full_name !== REPOSITORY || run.name !== 'TestFlight release') throw new Error('GitHub run identity mismatch');
  return run;
}
async function githubStatus(fetchImpl, release) {
  const run = await githubRun(fetchImpl, release.ciRunId, release.ciAttempt);
  if (run.head_sha !== release.ciCommit) throw new Error('GitHub workflow commit mismatch');
  if (run.status !== 'completed') return 'building';
  return run.conclusion === 'success' ? 'finished' : run.conclusion === 'cancelled' ? 'canceled' : run.conclusion === 'timed_out' ? 'timed_out' : 'failed';
}
module.exports = {REPOSITORY,githubIdentity,githubRun,githubStatus};
