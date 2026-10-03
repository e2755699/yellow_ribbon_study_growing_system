'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {planClientMetadata,documents} = require('./roster-client-plan.cjs');
const {expectedDocuments,verifySnapshot,applyMetadataPlan,verifyMetadataPlan} = require('./roster-client-admin.cjs');
const clone = value => structuredClone(value);
function backupOf(entries) {
  const collections = {};
  for (const [path,data] of entries) {
    const parts = path.split('/'), id = parts.pop(), collection = parts.join('/');
    (collections[collection] ||= []).push({id,data:clone(data)});
  }
  return {schemaVersion:1,projectId:'demo-roster-client-cutover',exportedAt:'2026-10-03T00:00:00Z',
    documentCount:entries.size,collections};
}
function fixture(size = 1) {
  const rows = new Map([
    ['app_config/roster',{status:'maintenance',legacyWritesBlocked:true,clientWritesEnabled:false}],
    ['class_locations/a',{name:'合成甲點'}],['class_locations/b',{name:'合成乙點'}],
    ['class_locations/history',{name:'歷史據點'}],
    ['staff_access/teacher',{active:true,role:'teacher',locationIds:['a']}],
    ['record_operations/old',{uid:'teacher',action:'saveRecord',result:{revision:1},locationIds:['a']}],
    ['students/s0/notes/nested',{untouched:true}],
    ['performance_records/2026-10-02.a.s0',{values:{performanceRating:'excellent'},awardActive:false,provenance:'legacyUnverified'}],
  ]);
  for (let i = 0; i < size; i++) {
    rows.set('students/s'+i,{name:'合成學生'+i,revision:7,enrollmentRevision:4,
      birthday:{$firestore:'timestamp',seconds:1000,nanoseconds:3}});
    rows.set('student_summaries/s'+i,{name:'合成學生'+i,archived:false,locationIds:['history','a','b']});
    rows.set('student_enrollments/old'+i,{studentId:'s'+i,locationId:'a',startDate:'2026-01-01',endDateExclusive:'2026-10-03',startKnown:false,revision:2});
    rows.set('student_enrollments/new'+i,{studentId:'s'+i,locationId:'b',startDate:'2026-10-03',endDateExclusive:'9999-12-31',revision:1});
    // A reversed award may legitimately leave total below used.
    rows.set('yellow_ribbon_counts/s'+i,{totalCount:3,usedCount:4,lastUpdated:{$firestore:'timestamp',seconds:2000,nanoseconds:0}});
  }
  return backupOf(rows);
}
function change(backup,path,data) {
  const rows = documents(backup);
  if (data === undefined) rows.delete(path); else rows.set(path,data);
  return backupOf(rows);
}
class FakeDatabase {
  constructor(backup) { this.rows = documents(clone(backup)); this.transactions = 0; this.failAt = 0; }
  doc(path) { return {path,get:async () => this.snapshot(path)}; }
  snapshot(path) { return {ref:this.doc(path),exists:this.rows.has(path),data:() => clone(this.rows.get(path))}; }
  async runTransaction(body) {
    this.transactions++;
    if (this.beforeTransaction) await this.beforeTransaction(this);
    if (this.failAt === this.transactions) throw Error('synthetic connection loss');
    const pending = new Map();
    const result = await body({getAll:async (...refs) => refs.map(r => this.snapshot(r.path)),
      set:(ref,data) => pending.set(ref.path,clone(data))});
    for (const [path,data] of pending) this.rows.set(path,data);
    return result;
  }
}
const codec = {encode:clone,decode:clone,exportDatabase:async db => backupOf(db.rows)};
test('deterministic backfill preserves history ACL, exact balances, flags, receipts, profile data and nested history',async () => {
  const backup = fixture(), saved = clone(backup), plan = planClientMetadata(backup);
  assert.deepEqual(plan.conflicts,[]);
  assert.deepEqual(plan,planClientMetadata(backup));
  assert.deepEqual(backup,saved);
  const db = new FakeDatabase(backup);
  assert.equal((await applyMetadataPlan(db,backup,plan,codec)).applied,plan.writes.length);
  const result = await verifyMetadataPlan(db,backup,plan,codec);
  assert.equal(result.rewardsUnchanged,true);
  assert.deepEqual(db.rows,expectedDocuments(backup,plan));
  const student = db.rows.get('students/s0');
  assert.equal(student.revision,7); assert.equal(student.enrollmentRevision,4);
  assert.deepEqual(student.timelineSites,['a','b','history']);
  assert.equal(student.enrollmentTimeline[0].startKnown,false);
  assert.equal(student.enrollmentTimeline[1].startKnown,true);
  assert.equal(db.rows.get('yellow_ribbon_counts/s0').totalCount,3);
  assert.equal(db.rows.get('yellow_ribbon_counts/s0').usedCount,4);
  assert.deepEqual(db.rows.get('membership_indexes/a').changedEnrollmentIds,[]);
  assert.equal(db.rows.get('membership_indexes/a').entries.old0.endDateExclusive,'2026-10-03');
  assert.equal(planClientMetadata(backupOf(db.rows)).writes.length,0);
});
test('interrupted chunks resume with identical backup/plan, then rerun performs zero writes',async () => {
  const backup = fixture(30), plan = planClientMetadata(backup), db = new FakeDatabase(backup);
  assert.ok(plan.writes.length > 50);
  db.failAt = 2;
  await assert.rejects(applyMetadataPlan(db,backup,plan,codec),/synthetic/);
  await assert.rejects(verifyMetadataPlan(db,backup,plan,codec),/changed/);
  db.failAt = 0;
  const resume = await applyMetadataPlan(db,backup,plan,codec);
  assert.equal(resume.skipped,50); assert.equal(resume.applied,plan.writes.length - 50);
  assert.equal((await verifyMetadataPlan(db,backup,plan,codec)).verified,plan.writes.length);
  assert.equal((await applyMetadataPlan(db,backup,plan,codec)).applied,0);
});
test('edited plan and incomplete backup fail before writes',async () => {
  const backup = fixture(), plan = planClientMetadata(backup), db = new FakeDatabase(backup);
  await assert.rejects(applyMetadataPlan(db,backup,{...plan,writes:[]},codec),/differs/);
  assert.throws(() => planClientMetadata({...backup,documentCount:1}),/count mismatch/);
  assert.equal(db.transactions,0);
});
test('maintenance and both write barriers are required in backup and in each atomic chunk',async () => {
  for (const patch of [{status:'enabled'},{legacyWritesBlocked:false},{clientWritesEnabled:true},{clientWritesEnabled:undefined}]) {
    const backup = fixture(), plan = planClientMetadata(backup), db = new FakeDatabase(backup);
    db.rows.set('app_config/roster',{...db.rows.get('app_config/roster'),...patch});
    await assert.rejects(applyMetadataPlan(db,backup,plan,codec),/Requires/);
    const unsafeBackup = backupOf(db.rows), unsafePlan = planClientMetadata(unsafeBackup);
    assert.ok(unsafePlan.warnings.some(w => w.kind === 'preview-only-backup-not-frozen'));
    await assert.rejects(applyMetadataPlan(db,unsafeBackup,unsafePlan,codec),/Requires/);
  }
  const backup = fixture(), plan = planClientMetadata(backup), db = new FakeDatabase(backup);
  db.beforeTransaction = db => db.rows.get('app_config/roster').clientWritesEnabled = true;
  await assert.rejects(applyMetadataPlan(db,backup,plan,codec),/Requires/);
  assert.equal(db.rows.has('membership_indexes/a'),false);
});
test('changed source, extra history, ACL changes, removed records and overwritten destination all stop apply',async () => {
  const backup = fixture(), plan = planClientMetadata(backup);
  const mutations = [
    db => db.rows.get('students/s0').name = 'different',
    db => db.rows.set('record_operations/new',{action:'saveRecord'}),
    db => db.rows.get('staff_access/teacher').locationIds.push('b'),
    db => db.rows.delete('performance_records/2026-10-02.a.s0'),
    db => db.rows.set('membership_indexes/a',{entries:{rogue:{studentId:'s0'}},changedEnrollmentIds:[]}),
  ];
  for (const mutate of mutations) {
    const db = new FakeDatabase(backup); mutate(db);
    await assert.rejects(applyMetadataPlan(db,backup,plan,codec),/changed/);
    assert.equal(db.transactions,0);
  }
  const db = new FakeDatabase(backup);
  db.beforeTransaction = db => db.rows.set('membership_indexes/a',{entries:{rogue:{}},changedEnrollmentIds:[]});
  await assert.rejects(applyMetadataPlan(db,backup,plan,codec),/Destination changed/);
  assert.equal(db.rows.has('membership_indexes/b'),false);
});
test('unrelated CI documents may evolve; roster history and receipts must remain unchanged',() => {
  const backup = fixture(), plan = planClientMetadata(backup);
  const rows = expectedDocuments(backup,plan);
  rows.set('release_jobs/ci',{status:'complete'});
  assert.doesNotThrow(() => verifySnapshot(backup,plan,backupOf(rows),{complete:true}));
  rows.get('record_operations/old').result.revision = 2;
  assert.throws(() => verifySnapshot(backup,plan,backupOf(rows),{complete:true}),/changed/);
});
test('missing wallet initializes zero without inventing enrollment for historical orphan summary',async () => {
  let backup = change(fixture(),'yellow_ribbon_counts/s0',undefined);
  backup = change(backup,'student_summaries/orphan',{name:'歷史合成學生',locationIds:['history'],archived:true});
  backup = change(backup,'yellow_ribbon_counts/orphan',{totalCount:8,usedCount:2});
  const plan = planClientMetadata(backup), db = new FakeDatabase(backup);
  assert.deepEqual(plan.conflicts,[]);
  await applyMetadataPlan(db,backup,plan,codec);
  assert.equal(db.rows.get('yellow_ribbon_counts/s0').totalCount,0);
  assert.equal(db.rows.get('yellow_ribbon_counts/orphan').totalCount,8);
  assert.equal(db.rows.has('students/orphan'),false);
});
test('invalid, overlapping, orphan and unknown-site enrollment or ACL data are conflicts, never guessed',() => {
  const original = fixture(), e = documents(original).get('student_enrollments/new0');
  for (const replacement of [
    {...e,startDate:'2026-10-02'}, {...e,startDate:'2026-02-30'},
    {...e,studentId:'missing'}, {...e,locationId:'missing'}, {...e,startKnown:'true'},
  ]) assert.ok(planClientMetadata(change(original,'student_enrollments/new0',replacement)).conflicts.length);
  for (const [path,data] of [
    ['student_summaries/s0',undefined], ['yellow_ribbon_counts/orphan',{totalCount:1,usedCount:0}],
    ['yellow_ribbon_counts/s0',{totalCount:1.5,usedCount:0}],
    ['student_summaries/s0',{locationIds:['missing']}],
    ['students/s0',{name:'合成',timelineSites:'a'}],
  ]) assert.ok(planClientMetadata(change(original,path,data)).conflicts.length);
});
test('long enrollment history is retained; conservative site/document capacity rejects overflow without truncation',() => {
  let backup = fixture(), rows = documents(backup);
  rows.delete('student_enrollments/old0'); rows.delete('student_enrollments/new0');
  for (let i = 0; i < 101; i++) {
    const start = new Date(Date.UTC(2000,0,1 + i * 2)).toISOString().slice(0,10);
    const end = new Date(Date.UTC(2000,0,2 + i * 2)).toISOString().slice(0,10);
    rows.set('student_enrollments/p'+i,{studentId:'s0',locationId:'a',startDate:start,endDateExclusive:end,startKnown:true});
  }
  backup = backupOf(rows);
  const plan = planClientMetadata(backup);
  assert.deepEqual(plan.conflicts,[]);
  assert.equal(plan.writes.find(w => w.path === 'students/s0').data.enrollmentTimeline.length,101);
  rows.get('students/s0').remarks = 'x'.repeat(701 * 1024);
  assert.ok(planClientMetadata(backupOf(rows)).conflicts.some(c => c.kind === 'document-capacity-review-required'));
  const largePlan = planClientMetadata(fixture(1001));
  assert.ok(largePlan.conflicts.some(c => c.kind === 'site-history-capacity-review-required'));
  assert.equal(Object.keys(largePlan.writes.find(w => w.path === 'membership_indexes/a').data.entries).length,1001);
});
