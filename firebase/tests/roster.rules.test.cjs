'use strict';
const {before,after,beforeEach,test}=require('node:test');
const {readFileSync}=require('node:fs');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {doc,getDoc,setDoc,collection,getDocs,query,where,documentId,updateDoc}=require('firebase/firestore');
let env;
before(async()=>env=await initializeTestEnvironment({projectId:'demo-yellow-ribbon-roster',
  firestore:{host:'127.0.0.1',port:Number(process.env.ROSTER_RULES_PORT||8190),rules:readFileSync('../roster.rules','utf8')}}));
after(async()=>await env?.cleanup());
beforeEach(async()=>{
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async c=>{
    const db=c.firestore();
    await Promise.all([
      setDoc(doc(db,'app_config/roster'),{status:'enabled',clientWritesEnabled:true}),
      setDoc(doc(db,'staff_access/teacher'),{active:true,role:'teacher',locationIds:['a']}),
      setDoc(doc(db,'students/s'),{name:'合成學生',locationId:'a'}),
      setDoc(doc(db,'student_summaries/s'),{name:'合成學生',locationIds:['a']}),
      setDoc(doc(db,'attendance_records/a'),{studentId:'s',locationId:'a'}),
      setDoc(doc(db,'attendance_records/b'),{studentId:'t',locationId:'b'}),
    ]);
  });
});
test('site-constrained queries pass; cross-site and full collection queries fail',async()=>{
  const db=env.authenticatedContext('teacher').firestore();
  await assertSucceeds(getDocs(query(collection(db,'attendance_records'),where('locationId','==','a'))));
  await assertFails(getDocs(collection(db,'attendance_records')));
  await assertFails(getDoc(doc(db,'attendance_records/b')));
});
test('email and self-written role cannot grant staff access',async()=>{
  const db=env.authenticatedContext('outsider',{email:'synthetic@example.test'}).firestore();
  await assertSucceeds(setDoc(doc(db,'users/outsider'),{role:'owner'}));
  await assertFails(getDoc(doc(db,'students/s')));
  await assertFails(setDoc(doc(db,'staff_access/outsider'),{active:true,role:'owner',locationIds:['a']}));
});
test('direct records, rewards, memberships and legacy writes are denied',async()=>{
  const db=env.authenticatedContext('teacher').firestore();
  for(const path of ['attendance_records/a','performance_records/a','student_enrollments/e',
    'ribbon_events/e','yellow_ribbon_counts/s','daily_attendance/old','daily_performances/old',
    'record_operations/op','class_sessions/a'])
    await assertFails(setDoc(doc(db,path),{locationId:'a',studentId:'s'}));
});
test('profile updates cannot change site; anonymous access is denied',async()=>{
  const db=env.authenticatedContext('teacher').firestore();
  await assertFails(setDoc(doc(db,'students/s'),{name:'合成學生',locationId:'b'}));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(),'students/s')));
});

test('profile text uses command; only attachment links can be updated directly',async()=>{
  const db=env.authenticatedContext('teacher').firestore();
  await assertFails(updateDoc(doc(db,'students/s'),{name:'changed'}));
  await assertSucceeds(updateDoc(doc(db,'students/s'),{avatar:'synthetic.jpg'}));
});
test('eight authorized ribbon summaries fit per-query rule lookup limits',async()=>{
  const ids=Array.from({length:8},(_,i)=>'synthetic-'+i);
  await env.withSecurityRulesDisabled(async c=>{
    const setupDb=c.firestore();
    for(const sid of ids) {
      await setDoc(doc(setupDb,'student_summaries/'+sid),{locationIds:['a']});
      await setDoc(doc(setupDb,'yellow_ribbon_counts/'+sid),{totalCount:2,usedCount:1,locationIds:['a']});
    }
  });
  const db=env.authenticatedContext('teacher').firestore();
  await assertSucceeds(getDocs(query(collection(db,'yellow_ribbon_counts'),where(documentId(),'in',ids))));
  await assertFails(getDocs(collection(db,'yellow_ribbon_counts')));
});

test('receipts are owner scoped',async()=>{
  await env.withSecurityRulesDisabled(async c=>{
    await setDoc(doc(c.firestore(),'record_operations/own'),{uid:'teacher',locationIds:['a'],result:{values:{name:'合成'}}});
  });
  await assertSucceeds(getDoc(doc(env.authenticatedContext('teacher').firestore(),'record_operations/own')));
});
