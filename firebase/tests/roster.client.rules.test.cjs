'use strict';
const {before,after,beforeEach,test}=require('node:test');
const assert=require('node:assert/strict');
const {readFileSync}=require('node:fs');
const {initializeTestEnvironment,assertSucceeds,assertFails}=require('@firebase/rules-unit-testing');
const {doc,getDoc,setDoc,updateDoc,writeBatch,runTransaction,serverTimestamp}=require('firebase/firestore');
let env;
const DAY='2026-10-01';
const rid=s=>`${DAY}.a.${s}`;
const fields=['performanceRating','remarks','excellentCharacters','classPerformanceRating','mathPerformanceRating','chinesePerformanceRating','englishPerformanceRating','socialPerformanceRating'];
const blank={performanceRating:null,remarks:'',excellentCharacters:[],classPerformanceRating:null,mathPerformanceRating:null,chinesePerformanceRating:null,englishPerformanceRating:null,socialPerformanceRating:null};
const full={performanceRating:'excellent',remarks:'x'.repeat(4000),excellentCharacters:Array.from({length:30},(_,i)=>String(i).padEnd(80,'x')),classPerformanceRating:5,mathPerformanceRating:4,chinesePerformanceRating:3,englishPerformanceRating:2,socialPerformanceRating:1};
function record(s,kind){return {schemaVersion:2,studentId:s,locationId:'a',dateKey:DAY,enrollmentId:'e'+s,nameSnapshot:'Synthetic',revision:1,values:kind==='attendance'?{status:null,leaveReason:''}:blank,provenance:'confirmed',confirmedFields:[],updatedBy:'teacher',updatedAt:new Date(),lastOperationId:'seed',...(kind==='performance'?{awardActive:false,awardReviewRequired:false}:{})};}
before(async()=>env=await initializeTestEnvironment({projectId:'demo-yellow-ribbon-roster',firestore:{host:'127.0.0.1',port:Number(process.env.ROSTER_RULES_PORT||8190),rules:readFileSync('../roster.rules','utf8')}}));
after(async()=>env?.cleanup());
beforeEach(async()=>{
 await env.clearFirestore();
 await env.withSecurityRulesDisabled(async c=>{
 const db=c.firestore(),b=writeBatch(db),entries={};
 b.set(doc(db,'app_config/roster'),{status:'enabled',clientWritesEnabled:true});
 for(const [uid,role,locationIds] of [['teacher','teacher',['a']],['other','teacher',['b']],['manager','manager',['a','b']]]) b.set(doc(db,'staff_access/'+uid),{active:true,role,locationIds});
 for(let i=0;i<30;i++){const s='s'+i,p={id:'e'+s,studentId:s,locationId:'a',startDate:'2020-01-01',endDateExclusive:'9999-12-31',startKnown:true};
 entries[p.id]={studentId:s,locationId:'a',startDate:p.startDate,endDateExclusive:p.endDateExclusive};
 b.set(doc(db,'students/'+s),{id:s,name:'Synthetic',locationId:'a',revision:1,enrollmentRevision:1,enrollmentTimeline:[p],timelineSites:['a'],archived:false});
 b.set(doc(db,'student_summaries/'+s),{name:'Synthetic',locationIds:['a'],archived:false});
 b.set(doc(db,'student_enrollments/'+p.id),{...entries[p.id],startKnown:true,revision:1});
 for(const kind of ['attendance','performance'])b.set(doc(db,kind+'_records/'+rid(s)),record(s,kind));
 b.set(doc(db,'yellow_ribbon_counts/'+s),{totalCount:2,usedCount:1,locationIds:['a']});
 }
 b.set(doc(db,'membership_indexes/a'),{entries,changedEnrollmentIds:[]});await b.commit();
 });
});
function receipt(b,db,uid,op,action='saveRecords',sites=['a']){b.set(doc(db,'record_operations/'+op),{uid,hash:'a'.repeat(64),action,result:{records:{}},locationIds:sites,createdAt:serverTimestamp()});}
async function save(kind,{uid='teacher',invalid=-1,tagsOverride}={}){
 const db=env.authenticatedContext(uid).firestore(),b=writeBatch(db),op='op_'+kind;
 receipt(b,db,uid,op);
 for(let i=0;i<30;i++){const s='s'+i;const r={...record(s,kind),revision:2,values:kind==='attendance'?{status:'attend',leaveReason:''}:{...full},confirmedFields:kind==='attendance'?['status']:fields,updatedBy:uid,updatedAt:serverTimestamp(),lastOperationId:op};
 if(tagsOverride!==undefined && kind==='performance')r.values.excellentCharacters=tagsOverride;
 if(i===invalid)r.values[kind==='attendance'?'status':'mathPerformanceRating']=kind==='attendance'?'forged':8;
 if(kind==='performance')r.awardActive=true;
 b.set(doc(db,kind+'_records/'+rid(s)),r);
 if(kind==='performance'){
 b.update(doc(db,'yellow_ribbon_counts/'+s),{totalCount:3,lastUpdated:serverTimestamp(),updatedBy:uid,lastOperationId:op,locationId:'a',dateKey:DAY,enrollmentId:'e'+s});
 b.set(doc(db,'ribbon_events/'+op+'.'+s),{studentId:s,locationId:'a',recordId:rid(s),delta:1,kind:'award',dateKey:DAY,enrollmentId:'e'+s,updatedBy:uid,createdAt:serverTimestamp(),operationId:op});
 }
 }
 return b.commit();
}
async function unchanged(kind){await env.withSecurityRulesDisabled(async c=>{const db=c.firestore();for(let i=0;i<30;i++){assert.equal((await getDoc(doc(db,kind+'_records/'+rid('s'+i)))).data().revision,1);assert.equal((await getDoc(doc(db,'yellow_ribbon_counts/s'+i))).data().totalCount,2);assert.equal((await getDoc(doc(db,'ribbon_events/op_'+kind+'.s'+i))).exists(),false);}assert.equal((await getDoc(doc(db,'record_operations/op_'+kind))).exists(),false);});}
test('30 existing attendance records commit atomically',async()=>assertSucceeds(save('attendance')));
test('30 full performance records, wallets and immutable events commit atomically',async()=>assertSucceeds(save('performance')));
test('one illegal attendance row rejects all 30 writes',async()=>{await assertFails(save('attendance',{invalid:17}));await unchanged('attendance');});
test('one illegal full score rejects records, rewards and receipt together',async()=>{await assertFails(save('performance',{invalid:17}));await unchanged('performance');});
test('teacher cannot commit another site batch',async()=>{await assertFails(save('attendance',{uid:'other'}));await unchanged('attendance');});
test('revoked staff cannot commit pending edits',async()=>{await env.withSecurityRulesDisabled(c=>updateDoc(doc(c.firestore(),'staff_access/teacher'),{active:false}));await assertFails(save('attendance'));await unchanged('attendance');});
test('client gate blocks writes until backfill cutover',async()=>{await env.withSecurityRulesDisabled(c=>updateDoc(doc(c.firestore(),'app_config/roster'),{clientWritesEnabled:false}));await assertFails(save('attendance'));await unchanged('attendance');});
test('receipt replay requires original uid and all original sites',async()=>{
 await env.withSecurityRulesDisabled(async c=>{const db=c.firestore();await setDoc(doc(db,'record_operations/own'),{uid:'teacher',locationIds:['a'],result:{}});await setDoc(doc(db,'record_operations/old'),{uid:'teacher',locationIds:['a','b'],result:{}});});
 const db=env.authenticatedContext('teacher').firestore();await assertSucceeds(getDoc(doc(db,'record_operations/own')));await assertFails(getDoc(doc(db,'record_operations/old')));await assertFails(getDoc(doc(env.authenticatedContext('manager').firestore(),'record_operations/own')));
});
test('same wallet cannot redeem above available balance',async()=>{const db=env.authenticatedContext('teacher').firestore(),b=writeBatch(db);receipt(b,db,'teacher','redeem','redeemRibbon');const today=new Date(Date.now()+8*3600000).toISOString().slice(0,10);b.update(doc(db,'yellow_ribbon_counts/s0'),{usedCount:3,lastUpdated:serverTimestamp(),updatedBy:'teacher',lastOperationId:'redeem',locationId:'a',dateKey:today,enrollmentId:'es0'});await assertFails(b.commit());});
for(const [label,tagsValue] of Object.entries({number:[1],object:[{}],null:[null],tooLong:['x'.repeat(81)],tooMany:Array(31).fill('x'),delimiter:['x'.repeat(80)+'A'.repeat(80)+'B'+'x'],astralTooLong:['\u{1f600}'.repeat(41)]}))test('tag validation rejects '+label,async()=>{await assertFails(save('performance',{tagsOverride:tagsValue}));await unchanged('performance');});
test('tags accept exact UTF16 limits, newline, empty and separator-prefix text',async()=>assertSucceeds(save('performance',{tagsOverride:['\u{1f600}'.repeat(40),'\n'.repeat(80),'A'.repeat(80),'B','']})));
async function seedLongTimeline(){
 const timeline=Array.from({length:100},(_,i)=>{const start=new Date(Date.UTC(2000,0,i+1)).toISOString().slice(0,10),end=i===99?'9999-12-31':new Date(Date.UTC(2000,0,i+2)).toISOString().slice(0,10);return{id:'long'+i,studentId:'long',locationId:i%2?'b':'a',startDate:start,endDateExclusive:end,startKnown:true};});
 await env.withSecurityRulesDisabled(async c=>{const db=c.firestore(),b=writeBatch(db);b.set(doc(db,'staff_access/managerA'),{active:true,role:'manager',locationIds:['a']});
 b.set(doc(db,'students/long'),{id:'long',name:'Long',locationId:'b',revision:1,enrollmentRevision:1,enrollmentTimeline:timeline,timelineSites:['a','b'],archived:false});b.set(doc(db,'student_summaries/long'),{name:'Long',locationIds:['a','b'],archived:false,enrollmentTimeline:timeline});b.set(doc(db,'yellow_ribbon_counts/long'),{totalCount:0,usedCount:0,locationIds:['a','b']});
 for(const loc of ['a','b']){const entries={};for(const p of timeline.filter(x=>x.locationId===loc)){const{id,...data}=p;b.set(doc(db,'student_enrollments/'+id),{...data,revision:1});entries[id]={studentId:p.studentId,locationId:loc,startDate:p.startDate,endDateExclusive:p.endDateExclusive};}b.set(doc(db,'membership_indexes/'+loc),{entries,changedEnrollmentIds:[]});}await b.commit();});return timeline;
}
async function longCorrection(uid,corrupt=false,action='correctEnrollment'){const timeline=await seedLongTimeline();const db=env.authenticatedContext(uid).firestore(),b=writeBatch(db),op='long_correction';receipt(b,db,uid,op,action,['a','b']);const p={...timeline[50],startKnown:false};const next=[...timeline];next[50]=p;if(corrupt)next[20]={...next[20],studentId:'victim'};
 b.update(doc(db,'students/long'),{enrollmentTimeline:next,enrollmentChange:{kind:'replace',index:50},enrollmentRevision:2,updatedBy:uid,updatedAt:serverTimestamp(),lastOperationId:op});
 b.update(doc(db,'student_summaries/long'),{enrollmentTimeline:next});
 b.update(doc(db,'student_enrollments/long50'),{startKnown:false,revision:2,updatedBy:uid,updatedAt:serverTimestamp(),lastOperationId:op});
 b.update(doc(db,'yellow_ribbon_counts/long'),{lastUpdated:serverTimestamp(),updatedBy:uid,lastOperationId:op});return b.commit();}
test('manager changes one of 100 periods without scanning all dependent docs',async()=>assertSucceeds(longCorrection('manager')));
test('manager with only changed site cannot alter a student with other historical sites',async()=>assertFails(longCorrection('managerA')));
test('incremental correction cannot mutate an unannounced historical period',async()=>assertFails(longCorrection('manager',true)));
for(const [label,tagsValue] of Object.entries({emoji:['\u{1f600}'.repeat(40)],newline:['\n'.repeat(80)],prefix:['A'.repeat(80)],empty:['']}))test('tag boundary '+label,async()=>assertSucceeds(save('performance',{tagsOverride:tagsValue})));
test('effective profile access follows most recent period across 100 history entries',async()=>{await seedLongTimeline();await assertSucceeds(getDoc(doc(env.authenticatedContext('other').firestore(),'students/long')));await assertFails(getDoc(doc(env.authenticatedContext('teacher').firestore(),'students/long')));});
test('manager correction cannot modify a wallet confined to another site',async()=>{await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),'staff_access/managerB'),{active:true,role:'manager',locationIds:['b']}));const db=env.authenticatedContext('managerB').firestore(),b=writeBatch(db);receipt(b,db,'managerB','cross_wallet','saveRecord',['b']);b.update(doc(db,'yellow_ribbon_counts/s0'),{totalCount:99,lastUpdated:serverTimestamp(),updatedBy:'managerB',lastOperationId:'cross_wallet',locationId:'b',dateKey:DAY,enrollmentId:null,correctionReason:'valid reason'});await assertFails(b.commit());});
test('event cannot claim a student with no enrollment at the authorized site',async()=>{const db=env.authenticatedContext('teacher').firestore(),b=writeBatch(db);receipt(b,db,'teacher','fake_event');b.set(doc(db,'ribbon_events/fake_event.victim'),{studentId:'victim',locationId:'a',recordId:DAY+'.a.victim',dateKey:DAY,enrollmentId:'es0',kind:'award',delta:1,updatedBy:'teacher',createdAt:serverTimestamp(),operationId:'fake_event'});await assertFails(b.commit());});
test('teacher cannot undo manager cancellation as part of saving attendance',async()=>{await env.withSecurityRulesDisabled(c=>setDoc(doc(c.firestore(),'class_sessions/'+DAY+'.a'),{locationId:'a',dateKey:DAY,status:'cancelled',revision:1,reason:'holiday'}));const db=env.authenticatedContext('teacher').firestore(),b=writeBatch(db);receipt(b,db,'teacher','undo_cancel','setSession');b.update(doc(db,'class_sessions/'+DAY+'.a'),{status:'held',reason:'',revision:2,updatedBy:'teacher',updatedAt:serverTimestamp(),lastOperationId:'undo_cancel'});await assertFails(b.commit());});
test('transfer does not require an unrelated historical site permission',async()=>{
 const timeline=await seedLongTimeline();timeline[0]={...timeline[0],locationId:'x'};
 await env.withSecurityRulesDisabled(async c=>{const db=c.firestore();await updateDoc(doc(db,'students/long'),{enrollmentTimeline:timeline,timelineSites:['x','a','b']});await updateDoc(doc(db,'student_summaries/long'),{enrollmentTimeline:timeline,locationIds:['x','a','b']});await updateDoc(doc(db,'yellow_ribbon_counts/long'),{locationIds:['x','a','b']});await updateDoc(doc(db,'student_enrollments/long0'),{locationId:'x'});});
 const db=env.authenticatedContext('manager').firestore(),b=writeBatch(db),op='future_transfer',prior={...timeline[99],endDateExclusive:DAY},next={id:op,studentId:'long',locationId:'a',startDate:DAY,endDateExclusive:'9999-12-31',startKnown:true};const periods=[...timeline.slice(0,99),prior,next];receipt(b,db,'manager',op,'changeEnrollment',['b','a']);
 b.update(doc(db,'students/long'),{locationId:'a',enrollmentTimeline:periods,enrollmentChange:{kind:'transfer',index:99},enrollmentRevision:2,updatedBy:'manager',updatedAt:serverTimestamp(),lastOperationId:op});b.update(doc(db,'student_summaries/long'),{enrollmentTimeline:periods});b.update(doc(db,'yellow_ribbon_counts/long'),{lastUpdated:serverTimestamp(),updatedBy:'manager',lastOperationId:op});
 const {id:oldId,...oldData}=prior,{id:newId,...newData}=next;b.update(doc(db,'student_enrollments/'+oldId),{...oldData,revision:2,updatedBy:'manager',updatedAt:serverTimestamp(),lastOperationId:op});b.set(doc(db,'student_enrollments/'+newId),{...newData,revision:1,updatedBy:'manager',updatedAt:serverTimestamp(),lastOperationId:op});
 for(const p of [prior,next])b.update(doc(db,'membership_indexes/'+p.locationId),{['entries.'+p.id]:{studentId:p.studentId,locationId:p.locationId,startDate:p.startDate,endDateExclusive:p.endDateExclusive},changedEnrollmentIds:[p.id]});await assertSucceeds(b.commit());
});
test('concurrent redemptions cannot overspend a shared student wallet',async()=>{const db=env.authenticatedContext('teacher').firestore();const day=new Date(Date.now()+8*3600000).toISOString().slice(0,10);const spend=op=>runTransaction(db,async tx=>{const ref=doc(db,'yellow_ribbon_counts/s0'),snap=await tx.get(ref);await tx.get(doc(db,'record_operations/'+op));receipt(tx,db,'teacher',op,'redeemRibbon');tx.update(ref,{usedCount:snap.data().usedCount+1,lastUpdated:serverTimestamp(),updatedBy:'teacher',lastOperationId:op,locationId:'a',dateKey:day,enrollmentId:'es0'});});const outcomes=await Promise.allSettled([spend('spend1'),spend('spend2')]);assert.equal(outcomes.filter(x=>x.status==='fulfilled').length,1);assert.equal((await getDoc(doc(db,'yellow_ribbon_counts/s0'))).data().usedCount,2);});
test('changeEnrollment action cannot disguise a date/startKnown correction',async()=>assertFails(longCorrection('manager',false,'changeEnrollment')));
