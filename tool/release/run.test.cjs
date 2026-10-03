const {test}=require('node:test'), assert=require('node:assert/strict');
const {openVersion}=require('./run.cjs');
test('closed released version is bumped before upload; open version stays unchanged',()=>{assert.equal(openVersion('1.0.1',['1.0']),'1.0.1');assert.equal(openVersion('1.0.0',['1.0']),'1.0.1');assert.equal(openVersion('1.0.1',['1.0.1']),'1.0.2');assert.equal(openVersion('1.0.9',['1.0.10']),'1.0.11');});
