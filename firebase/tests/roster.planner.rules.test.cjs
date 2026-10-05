'use strict';
const {before,after,test}=require('node:test');
const {readFileSync}=require('node:fs');
const {initializeTestEnvironment,assertFails}=require('@firebase/rules-unit-testing');
const assert=require('node:assert/strict');
const {doc,setDoc,getDoc,runTransaction,serverTimestamp}=require('firebase/firestore');
let env;
const trace=JSON.parse(readFileSync('roster-planner-traces.json','utf8'));
function materialize(v){if(v===trace.timestampMarker)return serverTimestamp();if(Array.isArray(v))return v.map(materialize);if(v&&typeof v==='object')return Object.fromEntries(Object.entries(v).map(([k,x])=>[k,materialize(x)]));return v;}
before(async()=>{env=await initializeTestEnvironment({projectId:'demo-yellow-ribbon-roster',firestore:{host:'127.0.0.1',port:Number(process.env.ROSTER_RULES_PORT||8190),rules:readFileSync('../roster.rules','utf8')}});await env.clearFirestore();await env.withSecurityRulesDisabled(async c=>{const db=c.firestore();for(const [p,d] of Object.entries(trace.fixtures))await setDoc(doc(db,p),materialize(d));});});
after(async()=>env?.cleanup());
test('actual Dart planner reads and writes replay as client transactions',async()=>{for(const [i,step] of trace.transactions.entries()){const db=env.authenticatedContext(step.uid).firestore();try{await runTransaction(db,async tx=>{for(const p of step.reads)await tx.get(doc(db,p));for(const w of step.writes)tx.set(doc(db,w.path),materialize(w.data),{merge:w.merge});});}catch(e){throw new Error(`trace ${i} ${step.input.action} ${step.input.operationId}: ${e.message}`,{cause:e});}}});
test('full profile field ranges fit a real enrollment transaction',async()=>{await env.clearFirestore();await env.withSecurityRulesDisabled(async c=>{const db=c.firestore();for(const [p,d] of Object.entries(trace.fixtures))await setDoc(doc(db,p),materialize(d));});const step=structuredClone(trace.transactions[0]);const student=step.writes.find(w=>w.path==='students/s0').data;for(const k of ['gender','phone','idNumber','school','email','guardianName','guardianIdNumber','guardianCompany','guardianPhone','guardianEmail','emergencyContactName','emergencyContactIdNumber','emergencyContactCompany','emergencyContactPhone','emergencyContactEmail','description','specialDiseaseDescription','specialStudentDescription','pickupRequirementDescription','studentIntroduction','motto','interest','abilityEvaluation','learningGoals','resourcesAndScholarships','talentClass','specialCourse'])student[k]='x'.repeat(10000);for(const k of ['economicStatus','familyStatus','ethnicStatus'])student[k]=20;for(const k of ['hasSpecialDisease','isSpecialStudent','needsPickup'])student[k]=true;student.birthday=trace.timestampMarker;const db=env.authenticatedContext(step.uid).firestore();await runTransaction(db,async tx=>{for(const p of step.reads)await tx.get(doc(db,p));for(const w of step.writes)tx.set(doc(db,w.path),materialize(w.data),{merge:w.merge});});});

// Recreate a real planner snapshot immediately before a chosen operation.
async function beforeOperation(op) {
  await env.clearFirestore();
  const target=trace.transactions.findIndex(s=>s.input.operationId===op);
  assert.ok(target>=0, `missing trace ${op}`);
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore();
    for(const [p,d] of Object.entries(trace.fixtures)) await setDoc(doc(db,p),materialize(d));
    for(const step of trace.transactions.slice(0,target))
      for(const w of step.writes) await setDoc(doc(db,w.path),materialize(w.data),{merge:w.merge});
  });
  return structuredClone(trace.transactions[target]);
}
async function replay(step) {
  const db=env.authenticatedContext(step.uid).firestore();
  return runTransaction(db,async tx=>{
    for(const p of step.reads) await tx.get(doc(db,p));
    for(const w of step.writes) tx.set(doc(db,w.path),materialize(w.data),{merge:w.merge});
  });
}
function replaceDates(value,end) {
  if(!value||typeof value!=='object') return;
  if('endDateExclusive' in value) value.endDateExclusive=end;
  for(const child of Object.values(value)) replaceDates(child,end);
}
test('same-day cancellation retains profile, scores, wallet and audit documents',async()=>{
  const step=await beforeOperation('same_archive');
  await replay(step);
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore();
    assert.equal((await getDoc(doc(db,'students/same'))).data().archived,true);
    assert.equal((await getDoc(doc(db,'student_enrollments/same_enroll'))).data().endDateExclusive,trace.dateKey);
    assert.equal((await getDoc(doc(db,`performance_records/${trace.dateKey}.A.same`))).data().values.performanceRating,'excellent');
    assert.equal((await getDoc(doc(db,'yellow_ribbon_counts/same'))).data().totalCount,1);
    assert.ok((await getDoc(doc(db,'ribbon_events/same_record.same'))).exists());
  });
});
for(const kind of ['missing-index','backwards','correction-action','wrong-role','wrong-site']) {
  test(`same-day cancellation rejects ${kind} atomically`,async()=>{
    const step=await beforeOperation('same_archive');
    if(kind==='missing-index') step.writes=step.writes.filter(w=>!w.path.startsWith('membership_indexes/'));
    if(kind==='backwards') for(const w of step.writes) replaceDates(w.data,'2000-01-01');
    if(kind==='correction-action') step.writes.find(w=>w.path==='record_operations/same_archive').data.action='correctEnrollment';
    if(kind==='wrong-role'||kind==='wrong-site') await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),'staff_access/m'),
      {active:true,role:kind==='wrong-role'?'teacher':'manager',locationIds:kind==='wrong-site'?['B']:['A','B']}));
    await assertFails(replay(step));
    await env.withSecurityRulesDisabled(async c=>{
      const db=c.firestore();
      assert.equal((await getDoc(doc(db,'students/same'))).data().archived,false);
      assert.equal((await getDoc(doc(db,'student_enrollments/same_enroll'))).data().endDateExclusive,'9999-12-31');
      assert.equal((await getDoc(doc(db,'record_operations/same_archive'))).exists(),false);
    });
  });
}
test('new enrollment cannot create an empty period',async()=>{
  const step=await beforeOperation('same_enroll');
  for(const w of step.writes) replaceDates(w.data,trace.dateKey);
  await assertFails(replay(step));
});

test('same-day transfer requires permission at both sites',async()=>{
  const step=await beforeOperation('same_transfer');
  await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),'staff_access/m'),
    {active:true,role:'manager',locationIds:['A']}));
  await assertFails(replay(step));
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore();
    assert.equal((await getDoc(doc(db,'student_enrollments/same_reenroll'))).data().endDateExclusive,'9999-12-31');
    assert.equal((await getDoc(doc(db,'student_enrollments/same_transfer'))).exists(),false);
  });
});
