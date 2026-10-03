'use strict';
// MIG-A6: copy every Firestore document (nested collections, timestamps,
// references, bytes) from one project to another. Operator-only; the source is
// read-only. Run with authorized Application Default Credentials and keep every
// export inside .release-private/. Never commit student data or credentials.
const {isDeepStrictEqual: equal} = require('node:util');
const {createRequire} = require('node:module');
const {resolve,dirname} = require('node:path');
const {writeFileSync,mkdirSync,existsSync} = require('node:fs');
const {createHash} = require('node:crypto');
const requireBackend = createRequire(resolve(__dirname,'../../firebase/roster-functions/package.json'));
const {initializeApp,applicationDefault,deleteApp} = requireBackend('firebase-admin/app');
const {getFirestore} = requireBackend('firebase-admin/firestore');
const {decode,exportDatabase} = require('./roster-admin.cjs');

// Compare document data only; server create/update times cannot be copied.
function contents(backup) {
  const result = new Map();
  for (const [collection,rows] of Object.entries(backup.collections)) {
    for (const row of rows) result.set(`${collection}/${row.id}`,row.data);
  }
  return result;
}
function digest(map) {
  const sorted = [...map.entries()].sort(([a],[b]) => a.localeCompare(b));
  return createHash('sha256').update(JSON.stringify(sorted)).digest('hex');
}
function privateOutput(file,value) {
  const target = resolve(file);
  if (!target.split(/[\\/]/).includes('.release-private')) throw Error('Outputs must be inside .release-private');
  if (existsSync(target)) throw Error('Output already exists; choose a new filename');
  mkdirSync(dirname(target),{recursive:true});
  writeFileSync(target,JSON.stringify(value,null,2),{flag:'wx',mode:0o600});
}
function compare(source,destination) {
  const missing = [], extra = [], different = [];
  for (const [path,data] of source) {
    if (!destination.has(path)) missing.push(path);
    else if (!equal(destination.get(path),data)) different.push(path);
  }
  for (const path of destination.keys()) if (!source.has(path)) extra.push(path);
  return {missing,extra,different};
}
async function mirror(db,source,current) {
  const writer = db.bulkWriter();
  let written = 0, deleted = 0;
  for (const [path,data] of source) {
    if (equal(current.get(path),data)) continue;
    writer.set(db.doc(path),decode(data,db)); written++;
  }
  // Deepest paths first so a parent is never removed before its children.
  for (const path of [...current.keys()].filter(p => !source.has(p)).sort((a,b) => b.length - a.length)) {
    writer.delete(db.doc(path)); deleted++;
  }
  await writer.close();
  return {written,deleted};
}
async function main(args = process.argv.slice(2)) {
  const [action,sourceId,destinationId,reportFile] = args;
  if (!['copy','verify'].includes(action) || !sourceId || !destinationId || !reportFile || args.length !== 4) {
    throw Error('Usage: copy|verify SOURCE_PROJECT DESTINATION_PROJECT .release-private/REPORT.json');
  }
  if (sourceId === destinationId) throw Error('Source and destination must differ');
  if (destinationId === 'test-o9g27r') throw Error('Refusing to overwrite the legacy production project');
  if (process.env.FIRESTORE_EMULATOR_HOST) throw Error('Not for emulators; use the migration emulator suites');
  privateOutput(reportFile + '.lock',{startedAt:new Date().toISOString()});
  const credential = applicationDefault();
  const sourceApp = initializeApp({projectId:sourceId,credential},'source');
  const destinationApp = initializeApp({projectId:destinationId,credential},'destination');
  const sourceDb = getFirestore(sourceApp), destinationDb = getFirestore(destinationApp);
  try {
    const sourceBackup = await exportDatabase(sourceDb,sourceId);
    const source = contents(sourceBackup);
    let result = {action,sourceId,destinationId,sourceDocuments:source.size,sourceDigest:digest(source)};
    if (action === 'copy') {
      privateOutput(reportFile.replace(/\.json$/,'') + '.source-backup.json',sourceBackup);
      const before = contents(await exportDatabase(destinationDb,destinationId));
      result = {...result,destinationDocumentsBefore:before.size,...await mirror(destinationDb,source,before)};
    }
    const after = contents(await exportDatabase(destinationDb,destinationId));
    const diff = compare(source,after);
    result = {...result,destinationDocuments:after.size,destinationDigest:digest(after),
      missing:diff.missing.length,extra:diff.extra.length,different:diff.different.length,
      identical:!diff.missing.length && !diff.extra.length && !diff.different.length,
      finishedAt:new Date().toISOString()};
    privateOutput(reportFile,{...result,paths:diff});
    console.log(JSON.stringify(result));
    if (!result.identical) process.exitCode = 2;
  } finally {
    await sourceDb.terminate(); await destinationDb.terminate();
    await deleteApp(sourceApp); await deleteApp(destinationApp);
  }
}
if (require.main === module) main().catch(error => {console.error(error.message); process.exitCode = 1;});
module.exports = {contents,compare,digest};
