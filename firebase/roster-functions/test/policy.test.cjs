'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {mergeValues,validatePatch,date,scope} = require('../roster-service.cjs');
test('three way field merge preserves remote changes and rejects collisions',()=>{
  assert.deepEqual(mergeValues({remarks:'remote',mathPerformanceRating:3},
    {remarks:'',mathPerformanceRating:3},{mathPerformanceRating:4}),
    {remarks:'remote',mathPerformanceRating:4});
  assert.throws(()=>mergeValues({remarks:'remote'},{remarks:''},{remarks:'local'}),
    e=>e.code==='aborted');
});
test('status and reason are one conflict unit',()=>{
  assert.throws(()=>mergeValues({status:'leave',leaveReason:'remote'},
    {status:'leave',leaveReason:'old'},{status:'attend'}),e=>e.code==='aborted');
});
test('server validates dates, allowed fields, rating ranges and sites',()=>{
  assert.throws(()=>date('2026-02-30'));
  assert.equal(date('2026-10-02'),'2026-10-02');
  assert.throws(()=>validatePatch('attendance',{totalCount:99}));
  assert.throws(()=>validatePatch('performance',{mathPerformanceRating:6}));
  assert.doesNotThrow(()=>validatePatch('performance',{performanceRating:'terrible'}));
  assert.throws(()=>scope({active:true,role:'teacher',locationIds:['a']},'b'));
  assert.throws(()=>scope({active:true,role:'teacher',locationIds:['a']},'a',true));
  assert.doesNotThrow(()=>scope({active:true,role:'manager',locationIds:['a']},'a',true));
});
