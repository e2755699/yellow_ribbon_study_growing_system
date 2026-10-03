const {test}=require('node:test'),assert=require('node:assert/strict');
const {Store}=require('../store.cjs');
test('read retries a replaced generation instead of returning nonexistent record',async()=>{
  let meta=0,downloads=0;
  const bucket={file:(name,opts)=>({getMetadata:async()=>[{generation:String(++meta)}],download:async()=>{downloads++;if(opts.generation==='1')throw {code:404};return [Buffer.from('{"id":"release"}')];}})};
  const result=await new Store(bucket).read('release');assert.equal(result.generation,'2');assert.equal(result.value.id,'release');assert.equal(downloads,2);
});
test('compare-and-swap retries against fresh state after concurrent write',async()=>{
  let gen=1,value={count:0},conflicted=false;
  const bucket={file:(name,opts)=>({getMetadata:async()=>[{generation:String(gen)}],download:async()=>[Buffer.from(JSON.stringify(value))],save:async(bytes,options)=>{if(!conflicted){conflicted=true;gen++;value={count:4};throw {code:412};}assert.equal(options.preconditionOpts.ifGenerationMatch,String(gen));value=JSON.parse(bytes);gen++;}})};
  const result=await new Store(bucket).update('counter',old=>({count:old.count+1}));assert.equal(result.count,5);
});
