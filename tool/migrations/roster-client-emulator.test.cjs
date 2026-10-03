'use strict';
const {test,before,after,beforeEach} = require('node:test');
const assert = require('node:assert/strict');
const {createRequire} = require('node:module');
const {resolve} = require('node:path');
if (process.env.FIRESTORE_EMULATOR_HOST !== '127.0.0.1:8195') throw Error('Requires isolated emulator 127.0.0.1:8195');
const requireBackend = createRequire(resolve(__dirname,'../../firebase/roster-functions/package.json'));
const {initializeApp,deleteApp} = requireBackend('firebase-admin/app');
const {getFirestore,Timestamp} = requireBackend('firebase-admin/firestore');
const codec = require('./roster-admin.cjs');
const {planClientMetadata} = require('./roster-client-plan.cjs');
const {applyMetadataPlan,verifyMetadataPlan} = require('./roster-client-admin.cjs');
const projectId = 'demo-roster-client-cutover';
let app, db;
before(() => {app = initializeApp({projectId},'client-cutover'); db = getFirestore(app);});
after(async () => {await db.terminate(); await deleteApp(app);});
beforeEach(async () => {
  const response = await fetch(`http://127.0.0.1:8195/emulator/v1/projects/${projectId}/databases/(default)/documents`,{method:'DELETE'});
  assert.equal(response.ok,true);
  const batch = db.batch();
  batch.set(db.doc('app_config/roster'),{status:'maintenance',legacyWritesBlocked:true,clientWritesEnabled:false});
  batch.set(db.doc('class_locations/a'),{name:'合成甲點'});
  batch.set(db.doc('class_locations/history'),{name:'合成歷史點'});
  for (let i = 0; i < 30; i++) {
    batch.set(db.doc('students/s'+i),{name:'合成學生'+i,birthday:Timestamp.fromMillis(1000),revision:3,enrollmentRevision:2});
    batch.set(db.doc('student_summaries/s'+i),{name:'合成學生'+i,archived:false,locationIds:['a','history']});
    batch.set(db.doc('student_enrollments/e'+i),{studentId:'s'+i,locationId:'a',startDate:'2026-01-01',endDateExclusive:'9999-12-31',startKnown:false});
    batch.set(db.doc('yellow_ribbon_counts/s'+i),{totalCount:2,usedCount:3,lastUpdated:Timestamp.fromMillis(2000)});
  }
  batch.set(db.doc('students/s0/notes/n'),{bytes:Buffer.from('synthetic'),link:db.doc('students/s0')});
  batch.set(db.doc('record_operations/old'),{uid:'teacher',action:'saveRecord',result:{revision:1},locationIds:['a']});
  batch.set(db.doc('performance_records/2026-01-01.a.s0'),{awardActive:false,awardReviewRequired:true,provenance:'legacyUnverified',values:{performanceRating:'excellent'}});
  await batch.commit();
});
test('real Admin transaction backfill and resume preserve typed data, negative available balance and receipt history',async () => {
  const backup = await codec.exportDatabase(db,projectId), plan = planClientMetadata(backup);
  assert.deepEqual(plan.conflicts,[]); assert.ok(plan.writes.length > 50);
  const first = await applyMetadataPlan(db,backup,plan,codec);
  assert.equal(first.applied,plan.writes.length);
  assert.equal((await applyMetadataPlan(db,backup,plan,codec)).applied,0);
  assert.equal((await verifyMetadataPlan(db,backup,plan,codec)).verified,plan.writes.length);
  const student = (await db.doc('students/s0').get()).data();
  assert.equal(student.birthday.toMillis(),1000);
  assert.deepEqual(student.timelineSites,['a','history']);
  const notes = (await db.doc('students/s0/notes/n').get()).data();
  assert.equal(notes.bytes.toString(),'synthetic'); assert.equal(notes.link.path,'students/s0');
  assert.deepEqual((await db.doc('student_summaries/s0').get()).data().enrollmentTimeline,student.enrollmentTimeline);
  const count = (await db.doc('yellow_ribbon_counts/s0').get()).data();
  assert.equal(count.totalCount - count.usedCount,-1);
});
test('actual committed first chunk survives interruption; retry writes remaining chunks only',async () => {
  const backup = await codec.exportDatabase(db,projectId), plan = planClientMetadata(backup);
  let calls = 0;
  const interrupted = {doc:db.doc.bind(db),runTransaction:async body => {
    if (++calls === 2) throw Error('synthetic interruption');
    return db.runTransaction(body);
  }};
  const wrappedCodec = {...codec,exportDatabase:async () => codec.exportDatabase(db,projectId)};
  await assert.rejects(applyMetadataPlan(interrupted,backup,plan,wrappedCodec),/synthetic interruption/);
  await assert.rejects(verifyMetadataPlan(db,backup,plan,codec),/changed/);
  const resumed = await applyMetadataPlan(db,backup,plan,codec);
  assert.equal(resumed.skipped,50);
  assert.equal(resumed.applied,plan.writes.length - 50);
  await verifyMetadataPlan(db,backup,plan,codec);
});
test('real source changes or an enabled client gate prevent all migration writes',async () => {
  const backup = await codec.exportDatabase(db,projectId), plan = planClientMetadata(backup);
  await db.doc('record_operations/new').set({uid:'teacher',action:'saveRecord'});
  await assert.rejects(applyMetadataPlan(db,backup,plan,codec),/changed/);
  assert.equal((await db.collection('membership_indexes').get()).empty,true);
  await db.doc('record_operations/new').delete();
  await db.doc('app_config/roster').update({clientWritesEnabled:true});
  await assert.rejects(applyMetadataPlan(db,backup,plan,codec),/Requires/);
  assert.equal((await db.doc('students/s0').get()).data().enrollmentTimeline,undefined);
});
