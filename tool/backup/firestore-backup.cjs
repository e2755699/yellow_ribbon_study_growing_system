'use strict';
// MIG-A5: Spark-compatible Firestore backup. Managed export (gcloud firestore
// export) needs billing, so this reads every document with the Admin SDK and
// writes a typed JSON snapshot plus its SHA-256. Output must stay outside the
// repository because it contains student data.
// Usage: node tool/backup/firestore-backup.cjs PROJECT OUTPUT_DIR
const {createRequire} = require('node:module');
const {resolve,join,relative,isAbsolute} = require('node:path');
const {writeFileSync,mkdirSync} = require('node:fs');
const {createHash} = require('node:crypto');
const requireBackend = createRequire(resolve(__dirname,'../migrations/package.json'));
const {initializeApp,applicationDefault,deleteApp} = requireBackend('firebase-admin/app');
const {getFirestore} = requireBackend('firebase-admin/firestore');
const {exportDatabase} = require('../migrations/roster-admin.cjs');

function outsideRepository(dir) {
  const fromRepo = relative(resolve(__dirname,'../..'),resolve(dir));
  return fromRepo.startsWith('..') || isAbsolute(fromRepo);
}
async function main([projectId,outputDir] = process.argv.slice(2)) {
  if (!projectId || !outputDir) throw Error('Usage: firestore-backup.cjs PROJECT OUTPUT_DIR');
  if (!outsideRepository(outputDir)) throw Error('Backups contain student data; write them outside the repository');
  const app = initializeApp({projectId,credential:applicationDefault()});
  const db = getFirestore(app);
  try {
    const backup = await exportDatabase(db,projectId);
    const body = JSON.stringify(backup,null,2);
    const sha256 = createHash('sha256').update(body).digest('hex');
    const stamp = backup.exportedAt.replace(/[:.]/g,'-');
    mkdirSync(outputDir,{recursive:true});
    const file = join(outputDir,`${projectId}-${stamp}.json`);
    writeFileSync(file,body,{flag:'wx',mode:0o600});
    writeFileSync(file + '.sha256',`${sha256}  ${projectId}-${stamp}.json\n`,{flag:'wx'});
    console.log(JSON.stringify({projectId,documents:backup.documentCount,file,sha256}));
  } finally { await db.terminate(); await deleteApp(app); }
}
if (require.main === module) main().catch(error => {console.error(error.message); process.exitCode = 1;});
