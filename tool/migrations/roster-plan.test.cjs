const {test}=require('node:test');
const assert=require('node:assert/strict');
const {planMigration}=require('./roster-plan.cjs');
function fixture() {return {collections:{
  class_locations:[{id:'site',data:{name:'合成點'}}],
  students:[{id:'s',data:{name:'合成學生',classLocation:'合成點'}}],
  daily_attendance:[{id:'20261001_合成點',data:{records:[{sid:'s',name:'合成學生',status:'absent'}]}}],
  daily_performances:[{id:'2026-10-01_合成點',data:{records:[
    {sid:'s',name:'合成學生',performanceRating:'average',mathPerformanceRating:3},
    {sid:'old',name:'歷史學生',performanceRating:'excellent',homeworkCompleted:true},
  ]}}],
  yellow_ribbon_counts:[{id:'s',data:{totalCount:8,usedCount:2}}],
}};}
test('migration is deterministic, retains evidence and never invents attendance or rewards',()=>{
  const input=fixture(),one=planMigration(input,'2026-10-02'),two=planMigration(input,'2026-10-02');
  assert.deepEqual(one,two);assert.equal(one.conflicts.length,0);
  assert.deepEqual(one.dailyEvidence['2026-10-01.site'],['old','s']);
  assert.equal(one.writes.some(w=>w.path==='attendance_records/2026-10-01.site.old'),false);
  assert.equal(one.writes.some(w=>w.path.startsWith('yellow_ribbon_counts/')),false);
  const enrollment=one.writes.find(w=>w.path.startsWith('student_enrollments/')).data;
  assert.equal(enrollment.startKnown,false);assert.equal(enrollment.startDate,'2026-10-02');
  assert.equal(one.writes.find(w=>w.path==='attendance_records/2026-10-01.site.s').data.provenance,'legacyUnverified');
  assert.deepEqual(one.writes.find(w=>w.path==='performance_records/2026-10-01.site.old').data.values.excellentCharacters,['homeworkCompleted']);
});
test('conflicting compact and hyphen date documents are isolated',()=>{
  const input=fixture();
  input.collections.daily_attendance.push({id:'2026-10-01_合成點',data:{records:[{sid:'s',name:'合成學生',status:'attend'}]}});
  assert.equal(planMigration(input,'2026-10-02').conflicts[0].kind,'canonical-collision');
});
test('unknown site and malformed dates fail explicitly',()=>{
  const input=fixture();input.collections.students[0].data.classLocation='不存在';
  assert.equal(planMigration(input,'2026-10-02').conflicts[0].kind,'unknown-student-site');
  assert.throws(()=>planMigration(fixture(),'2026-02-30'));
});
