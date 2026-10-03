const {test}=require('node:test');
const assert=require('node:assert/strict');
test('production function entrypoint loads with the installed Admin SDK',()=>{
  const functions=require('../index.js');
  assert.equal(typeof functions.rosterCommand,'function');
  assert.deepEqual(Object.keys(functions),['rosterCommand']);
});
