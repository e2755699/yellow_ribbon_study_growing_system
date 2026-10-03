const {test}=require('node:test');
const assert=require('node:assert/strict');
test('roster deployment cannot recreate retired callable or scheduler',()=>{
  const fs=require('node:fs');
  const path=require('node:path');
  const config=require('../../roster.deploy.json');
  const pkg=require('../package.json');
  assert.equal(config.functions,undefined);
  assert.equal(pkg.dependencies['firebase-functions'],undefined);
  assert.equal(fs.existsSync(path.join(__dirname,'../index.js')),false);
  assert.equal(typeof require('firebase-admin/firestore').getFirestore,'function');
});
