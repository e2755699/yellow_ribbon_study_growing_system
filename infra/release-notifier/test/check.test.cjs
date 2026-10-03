'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {checkRelease} = require('../check.cjs');
const {APP, GROUP, ApiError} = require('../apple.cjs');
const release = {id:'test-12',appId:APP,version:'1.0.1',buildNumber:'12',commit:'b'.repeat(40),deadline:200000};
function fixture(state='PROCESSING') {
  let checks=0;
  return {get checks(){return checks;}, api:async path=>{
    if(path===`/v1/betaGroups/${GROUP}`)return {data:{attributes:{name:'yellowribbon',isInternalGroup:true}}};
    if(path.startsWith('/v1/builds?')){checks++;return {data:[{id:'build-12',attributes:{version:'12',processingState:state,expired:false}}]};}
    if(path.endsWith('/buildBetaDetail'))return {data:{attributes:{internalBuildState:'IN_BETA_TESTING'}}};
    if(path.includes('/builds?limit'))return {data:[{id:'build-12'}]};
    if(path.includes('/buildUploads/'))return {data:{attributes:{cfBundleShortVersionString:'1.0.1',cfBundleVersion:'99'}}};
    throw Error('Unexpected path');
  }};
}
test('one pending observation returns immediately for scheduling',async()=>{const f=fixture();const r=await checkRelease(f.api,release,null,100000);assert.equal(r.status,'pending');assert.equal(f.checks,1);});
test('only deadline converts pending to unknown; expired deadline does not loop',async()=>{const f=fixture();const r=await checkRelease(f.api,release,null,200000);assert.equal(r.status,'unknown');assert.equal(r.reason,'VERIFICATION_TIMEOUT');assert.equal(f.checks,1);});
test('ready requires genuine full Apple inspection',async()=>{const f=fixture('VALID');const r=await checkRelease(f.api,release,null,100000);assert.equal(r.status,'ready');assert.equal(r.releaseId,release.id);assert.equal(r.commit,release.commit);assert.equal(f.checks,1);});
test('invalid is a terminal Apple failure',async()=>{const r=await checkRelease(fixture('INVALID').api,release,null,100000);assert.equal(r.status,'failed');assert.equal(r.reason,'INVALID');});
test('wrong build webhook cannot trigger success for active release',async()=>{const f=fixture('VALID');assert.deepEqual(await checkRelease(f.api,release,'other-upload',100000),{ignored:true});assert.equal(f.checks,0);});
for (const status of [401,403,429,500,0]) test('API '+status+' has no in-process retry',async()=>{
  let calls=0;const api=async()=>{calls++;throw new ApiError(status,'synthetic error');};
  const r=await checkRelease(api,release,null,100000);assert.equal(calls,1);assert.equal(r.status,status===401||status===403?'unknown':'pending');
  const expired=await checkRelease(api,release,null,200000);assert.equal(expired.status,'unknown');
});
