const {test}=require('node:test'), assert=require('node:assert/strict');
const {createDispatcher}=require('../dispatch.cjs');
function fixture(status='finished') {
  const id='a'.repeat(24), records=new Map([[`releases/${id}.json`,{id,commit:'b'.repeat(40),branch:'master',deadline:Date.now()+900000,appId:'6746115397',version:'1.0.1',buildNumber:'12'}],['active.json',{id,until:Date.now()+900000}]]), tasks=[], posts=[];
  const store={read:async name=>({value:records.get(name)}), update:async(name,fn)=>{const value=fn(records.get(name));if(value!==undefined)records.set(name,value);return records.get(name);}};
  const options={store,notificationTag:'ci-notify/test',checkRelease:async release=>({...release,status:'ready',reason:'INTERNAL_TESTING_AVAILABLE',checkedAt:new Date().toISOString(),releaseId:release.id}),enqueue:async(...args)=>tasks.push(args),cmToken:{value:()=> 'synthetic-token'},logger:{info:()=>{},error:()=>{}},fetchImpl:async(url,options)=>{if(options.method==='POST'){posts.push(JSON.parse(options.body));return {ok:true,json:async()=>({buildId:'verifier-12'})};}return {ok:true,json:async()=>({build:{status,tag:'testflight/example'}})};}};
  return {id,records,tasks,posts,options,dispatch:(...args)=>createDispatcher(options)(...args)};
}
test('notification uses pinned automation tag independently of App tag',async()=>{const f=fixture();await f.dispatch(f.id,'upload-12');assert.equal(f.posts[0].tag,'ci-notify/test');assert.equal(f.posts[0].branch,undefined);assert.equal(f.posts[0].environment.variables.YR_APPLE_UPLOAD_ID,'upload-12');assert(f.tasks.length);});

test('notification uses its release region while old and new endpoints coexist',async()=>{const f=fixture();f.options.notificationUrl='https://us-central1-test-o9g27r.cloudfunctions.net/releaseNotifierFree';await f.dispatch(f.id);assert.equal(f.posts[0].environment.variables.YR_CI_URL,f.options.notificationUrl);});
test('failed CI clears release lock without claiming Apple failure',async()=>{const f=fixture('failed');await f.dispatch(f.id);assert.equal(f.records.get('active.json').until,0);assert.equal(f.records.get(`releases/${f.id}.json`).result.phase,'CI');assert.equal(f.posts.length,0);});
test('unfinished build waits and post-publish status check does not bypass webhook',async()=>{const f=fixture('building');await f.dispatch(f.id,undefined,'build_status');assert.equal(f.posts.length,0);assert.equal(f.tasks.length,1);const done=fixture();await done.dispatch(done.id,undefined,'build_status');assert.equal(done.posts.length,0);});
test('revoked CI token fails dispatch and recovery remains scheduled',async()=>{const f=fixture();f.options.fetchImpl=async(url,options)=>options.method==='POST'?{ok:false,status:401}:{ok:true,json:async()=>({build:{status:'finished'}})};await assert.rejects(f.dispatch(f.id),/HTTP 401/);assert(f.tasks.length);});
test('active verifier lease suppresses duplicate launch',async()=>{const f=fixture();f.records.get(`releases/${f.id}.json`).leaseUntil=Date.now()+600000;await f.dispatch(f.id);assert.equal(f.posts.length,0);assert.equal(f.tasks.length,1);});

test('completed verification with canceled notification job emits fallback alert',async()=>{const f=fixture('canceled'),errors=[];Object.assign(f.records.get(`releases/${f.id}.json`),{result:{status:'ready'},runId:'verifier-12'});f.options.logger.error=(...args)=>errors.push(args);await f.dispatch(f.id);assert.equal(errors.length,1);assert.equal(f.records.get(`releases/${f.id}.json`).notificationWorkflowState,'canceled');await f.dispatch(f.id);assert.equal(errors.length,1);assert.equal(f.posts.length,0);});

test('notification completion check waits for publishing and records finished job',async()=>{const f=fixture('publishing');Object.assign(f.records.get(`releases/${f.id}.json`),{result:{status:'ready'},runId:'verifier-12'});await f.dispatch(f.id);assert.equal(f.tasks.length,1);assert.equal(f.records.get(`releases/${f.id}.json`).notificationWorkflowState,undefined);f.options.fetchImpl=async()=>({ok:true,json:async()=>({build:{status:'finished'}})});await f.dispatch(f.id);assert.equal(f.records.get(`releases/${f.id}.json`).notificationWorkflowState,'finished');assert.equal(f.posts.length,0);});

test('expected failed verification with successful publisher does not raise mail failure alert',async()=>{const f=fixture('failed'),errors=[];Object.assign(f.records.get(`releases/${f.id}.json`),{result:{status:'unknown'},runId:'verifier-12'});f.options.logger.error=(...args)=>errors.push(args);f.options.fetchImpl=async()=>({ok:true,json:async()=>({build:{status:'failed',buildActions:[{name:'Publishing',status:'success'}]}})});await f.dispatch(f.id);assert.equal(errors.length,0);assert.equal(f.records.get(`releases/${f.id}.json`).notificationPublishingSucceeded,true);});


test('pending observation schedules another task without launching a Mac job',async()=>{
  const f=fixture();let checks=0;f.options.checkRelease=async()=>{checks++;return {status:'pending',reason:'APPLE_PROCESSING'};};
  await f.dispatch(f.id,'upload-12');assert.equal(checks,1);assert.equal(f.posts.length,0);
  const release=f.records.get(`releases/${f.id}.json`);assert.equal(release.checkAttempts,1);assert(release.leaseUntil>Date.now());
  assert(f.tasks.some(t=>t[0].includes('-observe-')));await f.dispatch(f.id,'upload-12');assert.equal(checks,1);assert.equal(f.posts.length,0);
});
test('ready after queued pending launches only one notification and persists exact observation',async()=>{
  const f=fixture();const ready=f.options.checkRelease;f.options.checkRelease=async()=>({status:'pending'});await f.dispatch(f.id);
  f.records.get(`releases/${f.id}.json`).leaseUntil=0;f.options.checkRelease=ready;await f.dispatch(f.id);
  assert.equal(f.posts.length,1);assert.equal(f.records.get(`releases/${f.id}.json`).verifiedResult.status,'ready');await f.dispatch(f.id);assert.equal(f.posts.length,1);
});
test('verification recovery is queued before Apple or Codemagic failure',async()=>{
  const f=fixture();f.options.checkRelease=async()=>{throw Error('interrupted');};await assert.rejects(f.dispatch(f.id),/interrupted/);
  assert.equal(f.posts.length,0);assert(f.tasks.some(t=>t[0].includes('-recover-')));
});
test('pending retry queue failure is recoverable and cannot send mail',async()=>{
  const f=fixture();f.options.checkRelease=async()=>({status:'pending'});const enqueue=f.options.enqueue;
  f.options.enqueue=async(...args)=>{if(args[0].includes('-observe-'))throw Error('queue outage');return enqueue(...args);};
  await assert.rejects(f.dispatch(f.id),/queue outage/);assert.equal(f.posts.length,0);assert(f.tasks.some(t=>t[0].includes('-recover-')));
});
test('wrong upload event schedules an independent check without launching CI',async()=>{
  const f=fixture();f.options.checkRelease=async()=>({ignored:true});await f.dispatch(f.id,'wrong-upload');assert.equal(f.posts.length,0);
  assert(f.tasks.some(t=>t[0].includes('-observe-')&&!t[1].uploadId));
});
test('terminal unknown is delivered without more Apple checks on launch retry',async()=>{
  const f=fixture();let checks=0;const ready=f.options.checkRelease;f.options.checkRelease=async r=>{checks++;return {...await ready(r),status:'unknown',reason:'VERIFICATION_TIMEOUT'};};
  const fetch=f.options.fetchImpl;f.options.fetchImpl=async(u,o)=>o.method==='POST'?{ok:false,status:503}:fetch(u,o);
  await assert.rejects(f.dispatch(f.id),/HTTP 503/);f.records.get(`releases/${f.id}.json`).leaseUntil=0;f.options.fetchImpl=fetch;await f.dispatch(f.id);
  assert.equal(checks,1);assert.equal(f.posts.length,1);
});

test('queued notification does not start a duplicate after launch lease expires',async()=>{
  const f=fixture();await f.dispatch(f.id);f.records.get(`releases/${f.id}.json`).leaseUntil=0;
  f.options.fetchImpl=async url=>({ok:true,json:async()=>({build:{status:url.endsWith('/verifier-12')?'queued':'finished'}})});await f.dispatch(f.id);assert.equal(f.posts.length,1);assert(f.tasks.some(t=>t[0].includes('-queued-')));
});
test('repeated notification failures stop launching Mac jobs and alert once',async()=>{
  const f=fixture();let errors=0;f.options.logger.error=()=>errors++;f.records.get(`releases/${f.id}.json`).notificationAttempts=3;
  await f.dispatch(f.id);await f.dispatch(f.id);assert.equal(f.posts.length,0);assert.equal(errors,1);assert.equal(f.records.get('active.json').until,0);
});

test('GitHub canceled build produces CI failure notification without calling Apple',async()=>{
  const f=fixture();const r=f.records.get(`releases/${f.id}.json`);
  Object.assign(r,{ciProvider:'github',ciRunId:'123',ciAttempt:'1',ciCommit:'c'.repeat(40)});
  f.options.checkRelease=async()=>{throw Error('Apple must not be checked for failed CI');};
  const original=f.options.fetchImpl;
  f.options.fetchImpl=async(u,o)=>u.startsWith('https://api.github.com/')?{ok:true,json:async()=>({id:123,run_attempt:1,head_sha:r.ciCommit,name:'TestFlight release',repository:{full_name:'e2755699/yellow_ribbon_study_growing_system'},status:'completed',conclusion:'cancelled'})}:original(u,o);
  await f.dispatch(f.id,undefined,'build_status');
  assert.equal(f.posts.length,1);assert.equal(r.result,undefined);
  const stored=f.records.get(`releases/${f.id}.json`).verifiedResult;
  assert.equal(stored.phase,'CI');assert.equal(stored.reason,'CI_CANCELED');assert.equal(stored.commit,r.commit);
});
