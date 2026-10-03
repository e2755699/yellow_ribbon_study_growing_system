'use strict';
// Run with an existing, authorized Application Default Credential. Never put a
// service-account key, access token, or exported student data in this repository.
const {resolve,dirname}=require('node:path');
const {readFileSync,writeFileSync,mkdirSync}=require('node:fs');
const {createHash}=require('node:crypto');
const {isDeepStrictEqual}=require('node:util');
const {initializeApp,applicationDefault,deleteApp}=require('firebase-admin/app');
const {getFirestore,Timestamp,GeoPoint,DocumentReference}=require('firebase-admin/firestore');
const {planMigration}=require('./roster-plan.cjs');
const sourceCollections=['students','class_locations','daily_attendance','daily_performances','yellow_ribbon_counts'];
const digest=value=>createHash('sha256').update(JSON.stringify(value)).digest('hex');
function encode(value) {
  if(value instanceof Timestamp) return {$firestore:'timestamp',seconds:value.seconds,nanoseconds:value.nanoseconds};
  if(value instanceof GeoPoint) return {$firestore:'geopoint',latitude:value.latitude,longitude:value.longitude};
  if(value instanceof DocumentReference) return {$firestore:'reference',path:value.path};
  if(Buffer.isBuffer(value)) return {$firestore:'bytes',base64:value.toString('base64')};
  if(Array.isArray(value)) return value.map(encode);
  if(value && typeof value==='object') return Object.fromEntries(Object.keys(value).sort().map(k=>[k,encode(value[k])]));
  return value;
}
function decode(value,db) {
  if(value?.$firestore==='timestamp') return new Timestamp(value.seconds,value.nanoseconds);
  if(value?.$firestore==='geopoint') return new GeoPoint(value.latitude,value.longitude);
  if(value?.$firestore==='reference') return db.doc(value.path);
  if(value?.$firestore==='bytes') return Buffer.from(value.base64,'base64');
  if(Array.isArray(value)) return value.map(v=>decode(v,db));
  if(value && typeof value==='object') return Object.fromEntries(Object.entries(value).map(([k,v])=>[k,decode(v,db)]));
  return value;
}
async function exportDatabase(db,projectId) {
  const collections={};
  let count=0;
  async function walk(collection) {
    const refs=await collection.listDocuments();
    const rows=[];
    for(const ref of refs.sort((a,b)=>a.id.localeCompare(b.id))) {
      const doc=await ref.get();
      if(doc.exists) {
        if(++count>100000) throw Error('Export exceeds reviewed document limit; no partial backup is written');
        rows.push({id:doc.id,data:encode(doc.data()),createTime:encode(doc.createTime),updateTime:encode(doc.updateTime)});
      }
      for(const nested of await ref.listCollections()) await walk(nested);
    }
    collections[collection.path]=rows;
  }
  for(const collection of await db.listCollections()) await walk(collection);
  return {schemaVersion:1,projectId,exportedAt:new Date().toISOString(),documentCount:count,
    collections:Object.fromEntries(Object.entries(collections).sort(([a],[b])=>a.localeCompare(b)))};
}
function privateOutput(path,data) {
  const target=resolve(path);
  if(!target.split(/[\\/]/).includes('.release-private')) throw Error('Exports and reports must be inside .release-private');
  mkdirSync(dirname(target),{recursive:true});
  writeFileSync(target,JSON.stringify(data,null,2),{flag:'wx',mode:0o600});
}
async function maintenance(db) {
  const data=(await db.doc('app_config/roster').get()).data();
  if(data?.status!=='maintenance' || data?.legacyWritesBlocked!==true)
    throw Error('Requires verified legacy write barrier and app_config/roster maintenance state');
}
async function assertUnchangedSources(db,backup,plan) {
  const patches=new Map(plan.writes.filter(w=>w.path.startsWith('students/')).map(w=>[w.path,w.data]));
  for(const collection of sourceCollections) {
    const current=await db.collection(collection).get();
    const previous=backup.collections[collection] || [];
    if(current.size!==previous.length) throw Error('Source collection count changed; repeat export and dry-run');
    const originals=new Map(previous.map(row=>[row.id,row.data]));
    for(const doc of current.docs) {
      const actual=encode(doc.data()),original=originals.get(doc.id);
      // A resumed migration may have already merged only this student's metadata.
      const migrated=collection==='students'?{...original,...patches.get(doc.ref.path),rosterMigrationId:plan.sourceHash}:null;
      if(!isDeepStrictEqual(actual,original) && !isDeepStrictEqual(actual,migrated))
        throw Error('Source changed after backup; stop and reconcile before retry');
    }
  }
}
async function applyPlan(db,backup,plan) {
  if(plan.conflicts.length) throw Error('Resolve dry-run conflicts before apply');
  const rebuilt=planMigration(backup,plan.cutoff);
  if(!isDeepStrictEqual(rebuilt,plan)) throw Error('Plan differs from its backup; regenerate rather than editing it');
  await maintenance(db);
  await assertUnchangedSources(db,backup,plan);
  await checkDestinations(db,plan,false);
  let applied=0,skipped=0;
  // Bounded transactions keep a large migration inside a short maintenance
  // window while rechecking the write barrier for every atomic chunk.
  for(let offset=0;offset<plan.writes.length;offset+=100) {
    const chunk=plan.writes.slice(offset,offset+100);
    const outcome=await db.runTransaction(async tx=>{
      const [gate,...documents]=await tx.getAll(db.doc('app_config/roster'),...chunk.map(w=>db.doc(w.path)));
      if(gate.data()?.status!=='maintenance' || gate.data()?.legacyWritesBlocked!==true) throw Error('Write barrier changed');
      let changed=0;
      for(let index=0;index<chunk.length;index++) {
      const write=chunk[index],old=documents[index],target=old.ref;
      const data={...write.data,rosterMigrationId:plan.sourceHash};
      if(old.exists && Object.entries(data).every(([k,v])=>isDeepStrictEqual(encode(old.data()[k]),v))) {
        continue;
      }
      if(write.path.startsWith('students/')) {
        const source=(backup.collections.students || []).find(s=>s.id===target.id);
        if(!old.exists || !isDeepStrictEqual(encode(old.data()),source?.data)) throw Error('Student changed after backup');
        tx.set(target,decode(data,db),{merge:true});
      } else {
        if(old.exists) throw Error('Destination already contains different data; do not overwrite');
        tx.create(target,decode(data,db));
      }
      changed++;
      }
      return changed;
    });
    applied+=outcome;skipped+=chunk.length-outcome;
  }
  return {applied,skipped,total:plan.writes.length,sourceHash:plan.sourceHash};
}
async function verifyPlan(db,backup,plan) {
  await maintenance(db);
  await assertUnchangedSources(db,backup,plan);
  await checkDestinations(db,plan,true);
  let verified=0;
  for(let offset=0;offset<plan.writes.length;offset+=100) {
    const chunk=plan.writes.slice(offset,offset+100);
    const docs=await db.getAll(...chunk.map(w=>db.doc(w.path)));
    for(let index=0;index<chunk.length;index++) {
    const write=chunk[index],actual=docs[index].data();
    if(!actual || actual.rosterMigrationId!==plan.sourceHash ||
      !Object.entries(write.data).every(([key,value])=>isDeepStrictEqual(encode(actual[key]),value)))
      throw Error('Destination verification failed; maintenance must remain enabled');
    verified++;
    }
  }
  return {verified,sourceHash:plan.sourceHash,sourceCounts:plan.sourceCounts,
    rewardsUnchanged:true,maintenanceRetained:true};
}
async function checkDestinations(db,plan,complete) {
  const targets=new Map(plan.writes.filter(w=>!w.path.startsWith('students/')).map(w=>[w.path,w.data]));
  for(const name of new Set([...targets.keys()].map(path=>path.split('/')[0]))) {
    const docs=await db.collection(name).get();
    if(complete && docs.size!==[...targets.keys()].filter(path=>path.startsWith(name+'/')).length)
      throw Error('Destination count differs from the reviewed plan');
    for(const doc of docs.docs) {
      const wanted=targets.get(doc.ref.path);
      if(!wanted || !isDeepStrictEqual(encode(doc.data()),{...wanted,rosterMigrationId:plan.sourceHash}))
        throw Error('Destination already contains different data; do not overwrite');
    }
  }
}
async function main() {
  const [action,projectId,backupPath,planPath,outputPath]=process.argv.slice(2);
  if(!['export','apply','verify'].includes(action)||!projectId||!backupPath)
    throw Error('Usage: roster-admin.cjs export PROJECT .release-private/backup.json | apply/verify PROJECT BACKUP PLAN REPORT');
  if(process.env.FIRESTORE_EMULATOR_HOST && !projectId.startsWith('demo-')) throw Error('Emulator requires a demo project');
  let credential;
  if(!process.env.FIRESTORE_EMULATOR_HOST) credential=applicationDefault();
  const app=initializeApp({projectId,...(credential?{credential}:{})}),db=getFirestore(app);
  try {
    if(action==='export') {
      const backup=await exportDatabase(db,projectId);privateOutput(backupPath,backup);
      console.log(JSON.stringify({documents:backup.documentCount,collections:Object.keys(backup.collections).length,hash:digest(backup)}));
    } else {
      const backup=JSON.parse(readFileSync(backupPath,'utf8')),plan=JSON.parse(readFileSync(planPath,'utf8'));
      if(backup.projectId!==projectId || digest(backup)!==plan.sourceHash) throw Error('Project or backup hash mismatch');
      const result=await (action==='apply'?applyPlan:verifyPlan)(db,backup,plan);
      privateOutput(outputPath,result);console.log(JSON.stringify(result));
    }
  } finally {await db.terminate();await deleteApp(app);}
}
if(require.main===module) main().catch(error=>{console.error(error.message);process.exitCode=1;});
module.exports={encode,decode,exportDatabase,applyPlan,verifyPlan};
