const {test}=require('node:test'), assert=require('node:assert/strict'), crypto=require('node:crypto');
const {createHandler}=require('../service.cjs');
function fixture() {
  const records=new Map(), tasks=new Map(), errors=[];
  const store={read:async name=>({value:records.get(name)||null}),update:async(name,fn)=>{const v=fn(records.get(name)||null);if(v!==undefined)records.set(name,v);return records.get(name);}};
  const options={store,enqueue:async(name,body)=>tasks.set(name,body),dispatch:async()=>{},ciToken:{value:()=> 'test-ci'},appleSecret:{value:()=> 'test-apple'},logger:{error:(...args)=>errors.push(args)}};
  const request=async(path,body,headers={authorization:'Bearer test-ci'})=>{
    let status=200,result; const res={status(n){status=n;return this;},json(v){result=v;return this;}};
    await createHandler(options)({method:'POST',path,body,rawBody:Buffer.from(JSON.stringify(body)),get:name=>headers[name]},res);return {status,result};
  };
  const webhook=async(d,valid=true)=>{const body={data:d},raw=JSON.stringify(body);return request('/apple',body,{'x-apple-signature':valid?'hmacsha256='+crypto.createHmac('sha256','test-apple').update(raw).digest('hex'):'invalid'});};
  return {records,tasks,options,request,webhook,errors};
}
const release={id:'run-12',appId:'6746115397',version:'1.0.1',buildNumber:'12',commit:'a'.repeat(40),branch:'codex/student-roster-integrity'};
const complete={id:'event-12',type:'buildUploadStateUpdated',attributes:{newState:'COMPLETE'},relationships:{instance:{data:{type:'buildUploads',id:'upload-12'}}}};
test('invalid signatures cannot create events or jobs',async()=>{const f=fixture();assert.equal((await f.webhook(complete,false)).status,401);assert.equal(f.records.size,0);assert.equal(f.tasks.size,0);});
test('registration serializes releases and preserves exact identity',async()=>{const f=fixture();assert.equal((await f.request('/register',release)).status,200);assert.equal((await f.request('/register',{...release,id:'run-other'})).status,409);assert.equal((await f.request('/register',{...release,buildNumber:'13'})).status,409);assert.equal(f.records.get('releases/run-12.json').buildNumber,'12');});
test('duplicate webhook keeps one durable receipt and deterministic task',async()=>{const f=fixture();await f.request('/register',release);await f.webhook(complete);await f.webhook(complete);assert.equal([...f.records.keys()].filter(x=>x.startsWith('events/')).length,1);assert.deepEqual(f.tasks.get('event-event-12'),{id:'run-12',uploadId:'upload-12'});});
test('queue failure is not acknowledged and a retry repairs it',async()=>{const f=fixture();await f.request('/register',release);const enqueue=f.options.enqueue;f.options.enqueue=async()=>{throw Error('queue outage');};assert.equal((await f.webhook(complete)).status,503);f.options.enqueue=enqueue;assert.equal((await f.webhook(complete)).status,200);assert(f.tasks.has('event-event-12'));});
test('only one verifier owns release and only one terminal result can notify',async()=>{const f=fixture();await f.request('/register',release);assert((await f.request('/claim',{id:release.id,runId:'verify-1'})).result.claimed);assert(!(await f.request('/claim',{id:release.id,runId:'verify-2'})).result.claimed);const body={id:release.id,runId:'verify-1',result:{appId:release.appId,version:release.version,buildNumber:release.buildNumber,status:'ready'}};assert((await f.request('/finish',body)).result.notify);assert(!(await f.request('/finish',body)).result.notify);assert.equal(f.records.get('active.json').until,0);});
test('wrong build cannot complete release, and expired verifier lease can be recovered',async()=>{const f=fixture();await f.request('/register',release);await f.request('/claim',{id:release.id,runId:'verify-1'});const old=f.records.get('releases/run-12.json');old.leaseUntil=Date.now()-1;assert((await f.request('/claim',{id:release.id,runId:'verify-2'})).result.claimed);assert.equal((await f.request('/finish',{id:release.id,runId:'verify-2',result:{appId:release.appId,version:release.version,buildNumber:'99',status:'ready'}})).status,503);assert(!f.records.get('releases/run-12.json').result);});
test('unauthorized request cannot register or inspect release records',async()=>{const f=fixture();assert.equal((await f.request('/register',release,{})).status,401);assert.equal(f.records.size,0);});
