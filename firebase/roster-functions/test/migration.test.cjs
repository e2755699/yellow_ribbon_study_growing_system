'use strict';
const {test,before,after,beforeEach}=require('node:test');
const assert=require('node:assert/strict');
const {initializeApp,deleteApp}=require('firebase-admin/app');
const {getFirestore,Timestamp}=require('firebase-admin/firestore');
const {exportDatabase,applyPlan,verifyPlan}=require('../../../tool/migrations/roster-admin.cjs');
const {planMigration}=require('../../../tool/migrations/roster-plan.cjs');
if(process.env.FIRESTORE_EMULATOR_HOST!=='127.0.0.1:8190') throw Error('Requires isolated emulator');
const projectId='demo-yellow-ribbon-roster';
let app,db;
before(()=>{app=initializeApp({projectId},'migration');db=getFirestore(app);});
after(async()=>{await db.terminate();await deleteApp(app);});
beforeEach(async()=>{
  await fetch('http://127.0.0.1:8190/emulator/v1/projects/'+projectId+'/databases/(default)/documents',{method:'DELETE'});
  await Promise.all([
    db.doc('class_locations/a').set({name:'合成點'}),
    db.doc('students/s').set({name:'合成學生',classLocation:'合成點',birthday:Timestamp.fromMillis(1000)}),
    db.doc('students/s/notes/nested').set({untouched:true}),
    db.doc('daily_attendance/20261001_合成點').set({records:[{sid:'s',status:'absent'}]}),
    db.doc('yellow_ribbon_counts/s').set({totalCount:5,usedCount:2}),
    db.doc('app_config/roster').set({status:'maintenance',legacyWritesBlocked:true}),
  ]);
});
test('full export retains nested collections; apply resumes idempotently and verifies unchanged rewards',async()=>{
  const backup=await exportDatabase(db,projectId),plan=planMigration(backup,'2026-10-02');
  assert.equal(backup.collections['students/s/notes'].length,1);
  assert.equal(backup.collections.students[0].data.birthday.$firestore,'timestamp');
  const first=await applyPlan(db,backup,plan),retry=await applyPlan(db,backup,plan);
  assert.equal(first.applied,plan.writes.length);assert.equal(retry.applied,0);
  assert.equal(retry.skipped,plan.writes.length);
  assert.equal((await verifyPlan(db,backup,plan)).verified,plan.writes.length);
  assert.equal((await db.doc('yellow_ribbon_counts/s').get()).data().totalCount,5);
});
test('changed source, edited plan and missing write barrier stop migration',async()=>{
  const backup=await exportDatabase(db,projectId),plan=planMigration(backup,'2026-10-02');
  await db.doc('students/s').update({name:'另一台的修改'});
  await assert.rejects(applyPlan(db,backup,plan),/Source changed/);
  await assert.rejects(applyPlan(db,backup,{...plan,writes:[]}),/Plan differs/);
  await db.doc('app_config/roster').update({status:'enabled'});
  await assert.rejects(applyPlan(db,backup,plan),/write barrier/);
  assert.equal((await db.collection('attendance_records').get()).size,0);
});
test('migration chunks more than 100 writes and retains conflicting raw evidence',async()=>{
  const batch=db.batch();
  for(let i=0;i<60;i++) batch.set(db.doc('students/s'+i),{name:'合成學生'+i,classLocation:'合成點'});
  batch.set(db.doc('daily_attendance/2026-10-01_合成點'),{records:[{sid:'s',status:'attend',leaveReason:''}]});
  await batch.commit();
  const backup=await exportDatabase(db,projectId),plan=planMigration(backup,'2026-10-02');
  assert.ok(plan.writes.length>100);assert.equal(plan.conflicts.length,0);
  assert.equal((await applyPlan(db,backup,plan)).applied,plan.writes.length);
  assert.equal((await verifyPlan(db,backup,plan)).verified,plan.writes.length);
  assert.equal((await applyPlan(db,backup,plan)).skipped,plan.writes.length);
  const row=(await db.doc('attendance_records/2026-10-01.a.s').get()).data();
  assert.equal(row.values.status,undefined);
  assert.deepEqual(row.legacyConflictFields,['status']);
  assert.equal((await db.collection('legacy_record_sources').get()).size,2);
});
