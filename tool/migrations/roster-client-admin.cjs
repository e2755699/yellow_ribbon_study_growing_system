'use strict';
// ROSTER-A2.1: operator-only metadata migration. Never toggles production gates.
const {isDeepStrictEqual: equal} = require('node:util');
const {resolve,dirname} = require('node:path');
const {readFileSync,writeFileSync,mkdirSync,existsSync} = require('node:fs');
const {planClientMetadata,documents,hash,guardedPath,requireFrozen} = require('./roster-client-plan.cjs');
function checkPlan(backup,plan) {
  if (!equal(planClientMetadata(backup),plan)) throw Error('Plan differs from verified backup; regenerate it');
  if (plan.conflicts.length) throw Error('Resolve every metadata-plan conflict before apply');
  requireFrozen(documents(backup).get('app_config/roster'));
}
function expectedDocuments(backup,plan) {
  const result = documents(structuredClone(backup));
  for (const write of plan.writes) result.set(write.path,{...result.get(write.path),...write.data});
  return result;
}
function verifySnapshot(backup,plan,current,{complete = false} = {}) {
  const before = documents(backup), after = expectedDocuments(backup,plan), actual = documents(current);
  if (current.projectId !== backup.projectId) throw Error('Snapshot project mismatch');
  requireFrozen(actual.get('app_config/roster'));
  for (const path of new Set([...before.keys(),...after.keys(),...actual.keys()])) {
    if (!guardedPath(path)) continue;
    if (!equal(actual.get(path),after.get(path)) && (complete || !equal(actual.get(path),before.get(path)))) {
      throw Error('Protected source/destination changed; retain maintenance and reconcile privately');
    }
  }
}
async function applyMetadataPlan(db,backup,plan,codec) {
  checkPlan(backup,plan);
  const {encode,decode,exportDatabase} = codec;
  verifySnapshot(backup,plan,await exportDatabase(db,backup.projectId));
  const before = documents(backup), after = expectedDocuments(backup,plan);
  let applied = 0, skipped = 0;
  // The migration is resumable across chunks; it is not one global transaction.
  // App writes remain blocked until a separate complete verification succeeds.
  for (let offset = 0; offset < plan.writes.length; offset += 50) {
    const chunk = plan.writes.slice(offset,offset + 50);
    const changed = await db.runTransaction(async tx => {
      const [gate,...snapshots] = await tx.getAll(db.doc('app_config/roster'),...chunk.map(w => db.doc(w.path)));
      requireFrozen(gate.data());
      let writes = 0;
      for (let i = 0; i < chunk.length; i++) {
        const path = chunk[i].path, snapshot = snapshots[i];
        const current = snapshot.exists ? encode(snapshot.data()) : undefined;
        if (equal(current,after.get(path))) continue;
        if (!equal(current,before.get(path))) throw Error('Destination changed since backup; no overwrite');
        tx.set(snapshot.ref,decode(after.get(path),db)); writes++;
      }
      return writes;
    });
    applied += changed; skipped += chunk.length - changed;
  }
  return {taskId:'ROSTER-A2.1',sourceHash:plan.sourceHash,applied,skipped,
    maintenanceRetained:true,verificationRequired:true};
}
async function verifyMetadataPlan(db,backup,plan,codec) {
  checkPlan(backup,plan);
  verifySnapshot(backup,plan,await codec.exportDatabase(db,backup.projectId),{complete:true});
  return {taskId:'ROSTER-A2.1',sourceHash:plan.sourceHash,verified:plan.writes.length,
    protectedCollectionsUnchangedExceptPlannedMetadata:true,rewardsUnchanged:true,
    maintenanceRetained:true,clientWritesEnabled:false};
}
function privateTarget(file) {
  const target = resolve(file || '');
  if (!target.split(/[\\/]/).includes('.release-private')) throw Error('Private outputs must be in .release-private');
  if (existsSync(target)) throw Error('Private output already exists; choose a new filename');
  return target;
}
function privateOutput(file,value) {
  const target = privateTarget(file);
  mkdirSync(dirname(target),{recursive:true});
  writeFileSync(target,JSON.stringify(value,null,2),{flag:'wx',mode:0o600});
}
async function main(args = process.argv.slice(2)) {
  const [action,...rest] = args;
  if (action === 'plan') {
    const [backupFile,planFile] = rest;
    if (!backupFile || !planFile || rest.length !== 2) throw Error('Usage: plan BACKUP PLAN');
    const plan = planClientMetadata(JSON.parse(readFileSync(backupFile,'utf8')));
    privateOutput(planFile,plan);
    console.log(JSON.stringify({taskId:plan.taskId,sourceHash:plan.sourceHash,writes:plan.writes.length,
      conflicts:plan.conflicts.length,warnings:plan.warnings.length,dryRun:true}));
    if (plan.conflicts.length) process.exitCode = 2;
    return;
  }
  const [projectId,backupFile,planFile,reportFile] = rest;
  if (!['export','apply','verify'].includes(action) || !projectId || !backupFile
      || (action !== 'export' && (!planFile || !reportFile))) {
    throw Error('Usage: plan BACKUP PLAN | export PROJECT BACKUP | apply/verify PROJECT BACKUP PLAN REPORT');
  }
  if (process.env.FIRESTORE_EMULATOR_HOST && !projectId.startsWith('demo-')) throw Error('Emulator requires demo project');
  // Reject an unusable report path before any migration write is attempted.
  privateTarget(action === 'export' ? backupFile : reportFile);
  const {initializeApp,applicationDefault,deleteApp} = require('firebase-admin/app');
  const {getFirestore} = require('firebase-admin/firestore');
  const codec = require('./roster-admin.cjs');
  const app = initializeApp({projectId,...(process.env.FIRESTORE_EMULATOR_HOST ? {} : {credential:applicationDefault()})});
  const db = getFirestore(app);
  try {
    if (action === 'export') {
      requireFrozen((await db.doc('app_config/roster').get()).data());
      const backup = await codec.exportDatabase(db,projectId);
      // Confirm the protected domain was stable throughout the full export.
      const emptyPlan = {writes:[]};
      verifySnapshot(backup,emptyPlan,await codec.exportDatabase(db,projectId),{complete:true});
      privateOutput(backupFile,backup);
      console.log(JSON.stringify({documents:backup.documentCount,sourceHash:hash(backup),frozen:true}));
    } else {
      const backup = JSON.parse(readFileSync(backupFile,'utf8')), plan = JSON.parse(readFileSync(planFile,'utf8'));
      if (backup.projectId !== projectId || plan.projectId !== projectId || hash(backup) !== plan.sourceHash) {
        throw Error('Project or backup hash mismatch');
      }
      const result = await (action === 'apply' ? applyMetadataPlan : verifyMetadataPlan)(db,backup,plan,codec);
      privateOutput(reportFile,result); console.log(JSON.stringify(result));
    }
  } finally { await db.terminate(); await deleteApp(app); }
}
if (require.main === module) main().catch(error => {console.error(error.message); process.exitCode = 1;});
module.exports = {checkPlan,expectedDocuments,verifySnapshot,applyMetadataPlan,verifyMetadataPlan};
