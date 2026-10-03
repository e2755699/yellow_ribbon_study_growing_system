'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {REPOSITORY,githubIdentity,githubStatus} = require('../ci.cjs');
const {validRelease} = require('../core.cjs');
const env={GITHUB_REPOSITORY:REPOSITORY,GITHUB_RUN_ID:'123',GITHUB_RUN_ATTEMPT:'2',GITHUB_SHA:'a'.repeat(40)};
test('GitHub re-run identity separates attempts and rejects foreign repositories',()=>{
  assert.equal(githubIdentity(env).id,'gh-123-2');
  assert.throws(()=>githubIdentity({...env,GITHUB_REPOSITORY:'someone/else'}));
  assert.throws(()=>githubIdentity({...env,GITHUB_RUN_ATTEMPT:'0'}));
  const r={...githubIdentity(env),appId:'6746115397',version:'1.0.1',buildNumber:'14',commit:'b'.repeat(40),branch:'master'};
  assert(validRelease(r));assert(!validRelease({...r,id:'gh-123-1'}));
});
test('GitHub source verification binds run, attempt and automation commit independently of App commit',async()=>{
  const release=githubIdentity(env);
  const run={id:123,run_attempt:2,head_sha:env.GITHUB_SHA,name:'TestFlight release',repository:{full_name:REPOSITORY},status:'completed',conclusion:'success'};
  const fetch=async()=>({ok:true,json:async()=>run});
  assert.equal(await githubStatus(fetch,release),'finished');
  for(const [value,want] of [['failure','failed'],['cancelled','canceled'],['timed_out','timed_out']]){run.conclusion=value;assert.equal(await githubStatus(fetch,release),want);}
  run.status='in_progress';assert.equal(await githubStatus(fetch,release),'building');
  run.head_sha='c'.repeat(40);await assert.rejects(githubStatus(fetch,release),/commit mismatch/);
});
test('GitHub lookup errors never invent a successful build',async()=>{
  await assert.rejects(githubStatus(async()=>({ok:false,status:429}),githubIdentity(env)),/HTTP 429/);
  await assert.rejects(githubStatus(async()=>({ok:true,json:async()=>({})}),githubIdentity(env)),/identity mismatch/);
});
