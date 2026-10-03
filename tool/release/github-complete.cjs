'use strict';
const fs = require('node:fs');
const {hook} = require('./run.cjs');
const {REPOSITORY} = require('../../infra/release-notifier/ci.cjs');
(async()=>{
  const event = JSON.parse(fs.readFileSync(process.env.GITHUB_EVENT_PATH,'utf8'));
  const run = event.workflow_run;
  if (event.repository?.full_name !== REPOSITORY || run?.name !== 'TestFlight release' || run.head_repository?.full_name !== REPOSITORY || !['push','workflow_dispatch'].includes(run.event)) throw new Error('Unexpected completed workflow');
  const runId = String(run.id), attempt = String(run.run_attempt);
  await hook('github-complete',{id:`gh-${runId}-${attempt}`,runId,attempt});
  console.log('Workflow completion reported for '+runId+'/'+attempt);
})().catch(e=>{console.error(e.message);process.exitCode=1;});
