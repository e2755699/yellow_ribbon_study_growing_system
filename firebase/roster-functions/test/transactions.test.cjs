'use strict';
const {test,before,beforeEach,after} = require('node:test');
const assert = require('node:assert/strict');
const {initializeApp,deleteApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {createRosterService} = require('../roster-service.cjs');
if (process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8190') {
  throw new Error('Requires isolated local Firestore emulator 127.0.0.1:8190');
}
const projectId='demo-yellow-ribbon-roster';
let app,db,service;
before(()=>{
  app=initializeApp({projectId},'roster-integration'); db=getFirestore(app);
  service=createRosterService(db,()=>new Date('2026-10-02T05:00:00Z'));
});
after(async()=>{await db.terminate();await deleteApp(app);});
beforeEach(async()=>{
  const clear=await fetch('http://127.0.0.1:8190/emulator/v1/projects/'+projectId+'/databases/(default)/documents',{method:'DELETE'});
  assert.equal(clear.ok,true);
  await Promise.all([
    db.doc('staff_access/manager').set({active:true,role:'manager',locationIds:['a','b']}),
    db.doc('staff_access/teacher').set({active:true,role:'teacher',locationIds:['a']}),
    db.doc('class_locations/a').set({name:'合成甲',active:true}),
    db.doc('class_locations/b').set({name:'合成乙',active:true}),
    db.doc('app_config/roster').set({status:'enabled'}),
  ]);
  await service.execute('manager',{action:'enrollStudent',operationId:'enrollment',
    studentId:'s',locationId:'a',startDate:'2026-10-02',profile:{name:'合成學生'}});
});
const save=(extra={})=>({action:'saveRecord',operationId:'save',kind:'attendance',
  studentId:'s',locationId:'a',dateKey:'2026-10-02',enrollmentId:'enrollment',
  base:{},patch:{status:'attend'},...extra});
test('record/session/receipt commit together; lost-response retry is identical',async()=>{
  const result=await service.execute('teacher',save());
  assert.deepEqual(await service.execute('teacher',save()),result);
  assert.equal((await db.doc('attendance_records/2026-10-02.a.s').get()).data().revision,1);
  assert.equal((await db.doc('class_sessions/2026-10-02.a').get()).data().status,'held');
  await assert.rejects(service.execute('teacher',save({patch:{status:'absent'}})),e=>e.code==='already-exists');
});
test('pre-enrollment, future and cross-site writes fail with no partial data',async()=>{
  for(const input of [save({dateKey:'2026-10-01'}),save({dateKey:'2026-10-03'}),save({locationId:'b'})])
    await assert.rejects(service.execute('teacher',input));
  assert.equal((await db.collection('attendance_records').get()).size,0);
  assert.equal((await db.collection('class_sessions').get()).size,0);
});
test('concurrent fields merge, same-field conflict does not overwrite',async()=>{
  await service.execute('teacher',save({kind:'performance',patch:{remarks:'',mathPerformanceRating:3}}));
  await Promise.all([
    service.execute('teacher',save({kind:'performance',operationId:'edit1',base:{remarks:'',mathPerformanceRating:3},patch:{remarks:'備註'}})),
    service.execute('teacher',save({kind:'performance',operationId:'edit2',base:{remarks:'',mathPerformanceRating:3},patch:{mathPerformanceRating:5}})),
  ]);
  const values=(await db.doc('performance_records/2026-10-02.a.s').get()).data().values;
  assert.equal(values.remarks,'備註');assert.equal(values.mathPerformanceRating,5);
  await assert.rejects(service.execute('teacher',save({kind:'performance',operationId:'edit3',
    base:{remarks:''},patch:{remarks:'不同'}})),e=>e.code==='aborted');
});
test('award/reversal/redemption commit once and preserve consumed history',async()=>{
  const input=save({kind:'performance',patch:{performanceRating:'excellent'}});
  await service.execute('teacher',input);await service.execute('teacher',input);
  assert.equal((await db.doc('yellow_ribbon_counts/s').get()).data().totalCount,1);
  await service.execute('teacher',{action:'redeemRibbon',operationId:'redeem',studentId:'s',amount:1});
  await service.execute('teacher',save({kind:'performance',operationId:'reverse',
    base:{performanceRating:'excellent'},patch:{performanceRating:'good'}}));
  const count=(await db.doc('yellow_ribbon_counts/s').get()).data();
  assert.equal(count.totalCount,0);assert.equal(count.usedCount,1);
  assert.equal((await db.collection('ribbon_events').get()).size,3);
});
test('legacy excellent never reverses an unproven historical award',async()=>{
  await db.doc('performance_records/2026-10-02.a.s').set({
    studentId:'s',locationId:'a',dateKey:'2026-10-02',revision:1,
    provenance:'legacyUnverified',values:{performanceRating:'excellent'}});
  await db.doc('yellow_ribbon_counts/s').set({totalCount:7,usedCount:2});
  const result=await service.execute('teacher',save({kind:'performance',
    base:{performanceRating:'excellent'},patch:{performanceRating:'average'}}));
  assert.equal(result.awardReviewRequired,true);
  assert.equal((await db.doc('yellow_ribbon_counts/s').get()).data().totalCount,7);
});
test('simultaneous transfers serialize without overlapping periods',async()=>{
  const transfer=operationId=>({action:'changeEnrollment',operationId,studentId:'s',
    effectiveDate:'2026-10-03',locationId:'b',mode:'transfer',expectedRevision:1});
  const results=await Promise.allSettled([
    service.execute('manager',transfer('transfer1')),service.execute('manager',transfer('transfer2'))]);
  assert.equal(results.filter(r=>r.status==='fulfilled').length,1);
  assert.equal((await db.collection('student_enrollments').where('studentId','==','s').get()).size,2);
  assert.equal((await db.doc('student_enrollments/enrollment').get()).data().endDateExclusive,'2026-10-03');
});
test('maintenance and revoked staff block changes',async()=>{
  await db.doc('app_config/roster').update({status:'maintenance'});
  await assert.rejects(service.execute('teacher',save()),e=>e.code==='failed-precondition');
  await db.doc('staff_access/teacher').update({active:false});
  await assert.rejects(service.execute('teacher',save()),e=>e.code==='permission-denied');
});
test('profile patch merges independent changes and updates shared name atomically',async()=>{
  const edit=(operationId,base,patch)=>service.execute('teacher',{
    action:'updateProfile',operationId,studentId:'s',base,patch});
  await edit('rename',{name:'合成學生'},{name:'更新合成學生'});
  await edit('phone',{phone:null},{phone:'synthetic-phone'});
  assert.equal((await db.doc('student_summaries/s').get()).data().name,'更新合成學生');
  assert.equal((await db.doc('students/s').get()).data().phone,'synthetic-phone');
  await assert.rejects(edit('stale',{name:'合成學生'},{name:'過期改名'}),e=>e.code==='aborted');
  await assert.rejects(edit('move',{}, {locationId:'b'}),e=>e.code==='invalid-argument');
});
test('future transfer roster is determined by date without a scheduled write',async()=>{
  await service.execute('manager',{action:'changeEnrollment',operationId:'future',studentId:'s',
    effectiveDate:'2026-10-03',locationId:'b',mode:'transfer',expectedRevision:1});
  assert.equal((await db.doc('students/s').get()).data().locationId,'a');
  const roster=async(site,day)=>(await db.collection('student_enrollments')
    .where('locationId','==',site).where('startDate','<=',day)
    .where('endDateExclusive','>',day).get()).docs.map(doc=>doc.data().studentId);
  assert.deepEqual(await roster('a','2026-10-02'),['s']);
  assert.deepEqual(await roster('b','2026-10-02'),[]);
  assert.deepEqual(await roster('a','2026-10-03'),[]);
  assert.deepEqual(await roster('b','2026-10-03'),['s']);
  // No background job is needed to make the effective-day roster correct.
  assert.equal((await db.doc('students/s').get()).data().locationId,'a');
});
test('historical period correction requires reason and checks all period overlaps',async()=>{
  const change={action:'correctEnrollment',operationId:'correct',studentId:'s',
    enrollmentId:'enrollment',startDate:'2026-09-01',endDateExclusive:'9999-12-31',
    expectedRevision:1,reason:'已核對紙本入班日期'};
  await assert.rejects(service.execute('teacher',change),e=>e.code==='permission-denied');
  await assert.rejects(service.execute('manager',{...change,reason:''}),e=>e.code==='invalid-argument');
  await service.execute('manager',change);
  assert.equal((await db.doc('student_enrollments/enrollment').get()).data().startDate,'2026-09-01');
  await service.execute('teacher',save({dateKey:'2026-10-01'}));
});
test('legacy unknown fields survive editing a known field',async()=>{
  await db.doc('performance_records/2026-10-02.a.s').set({studentId:'s',locationId:'a',
    dateKey:'2026-10-02',revision:1,provenance:'legacyUnverified',
    values:{remarks:'old',homeworkCompleted:true,oldHelperTag:'保留'}});
  await service.execute('teacher',save({kind:'performance',base:{remarks:'old'},patch:{remarks:'new'}}));
  const values=(await db.doc('performance_records/2026-10-02.a.s').get()).data().values;
  assert.equal(values.homeworkCompleted,true);assert.equal(values.oldHelperTag,'保留');
});
test('receipt replay after site revocation cannot disclose the old result',async()=>{
  await service.execute('teacher',save());
  await db.doc('staff_access/teacher').update({locationIds:[]});
  await assert.rejects(service.execute('teacher',save()),e=>e.code==='permission-denied');
});

test('confirming a remark does not validate legacy scores or award a ribbon',async()=>{
  await db.doc('performance_records/2026-10-02.a.s').set({studentId:'s',locationId:'a',
    dateKey:'2026-10-02',revision:1,provenance:'legacyUnverified',
    values:{remarks:'old',performanceRating:'average',mathPerformanceRating:3}});
  const result=await service.execute('teacher',save({kind:'performance',base:{remarks:'old'},patch:{remarks:'new'}}));
  assert.equal(result.provenance,'partiallyConfirmed');
  assert.deepEqual(result.confirmedFields,['remarks']);
  assert.equal((await db.collection('ribbon_events').get()).size,0);
  const rating=await service.execute('teacher',save({kind:'performance',operationId:'confirm-rating',
    base:result.values,patch:{mathPerformanceRating:3}}));
  assert.equal(rating.provenance,'partiallyConfirmed');
  assert.deepEqual(rating.confirmedFields,['remarks','mathPerformanceRating']);
});
test('cancelled class blocks attendance and performance with no award',async()=>{
  await service.execute('manager',{action:'setSession',operationId:'cancel',locationId:'a',
    dateKey:'2026-10-02',status:'cancelled',expectedRevision:0,reason:'合成停課原因'});
  await assert.rejects(service.execute('teacher',save()),e=>e.code==='failed-precondition');
  await assert.rejects(service.execute('teacher',save({kind:'performance',patch:{performanceRating:'excellent'}})),
    e=>e.code==='failed-precondition');
  assert.equal((await db.collection('ribbon_events').get()).size,0);
});
