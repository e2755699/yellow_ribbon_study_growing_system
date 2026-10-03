'use strict';
const {createHash}=require('node:crypto');
const {isDeepStrictEqual}=require('node:util');
const {readFileSync,writeFileSync}=require('node:fs');
const hash=x=>createHash('sha256').update(JSON.stringify(x)).digest('hex');
const dateKey=text=>{
  if(!/^\d{4}-\d{2}-\d{2}$/.test(text)||Number.isNaN(Date.parse(text))||
    new Date(text).toISOString().slice(0,10)!==text) throw Error('Invalid date');
  return text;
};
function planMigration(backup,cutoff) {
  dateKey(cutoff);
  const collections=backup.collections;
  if(!collections) throw Error('Expected normalized collection export');
  const conflicts=[],warnings=[],writes=new Map(),summaries=new Map(),sites=new Map();
  const sourceCounts=Object.fromEntries(Object.entries(collections).map(([key,rows])=>[key,rows.length]));
  function put(path,data,source) {
    const old=writes.get(path);
    if(old&&!isDeepStrictEqual(old.data,data)) {
      if(/^(attendance_records|performance_records)\//.test(path) &&
        old.data.provenance==='legacyUnverified' && data.provenance==='legacyUnverified') {
        // Conflicting legacy snapshots are evidence, not a basis for choosing
        // attendance. Keep every original below; expose only agreeing fields.
        const disputed=new Set(old.data.legacyConflictFields || []);
        const values={...old.data.values};
        for(const field of new Set([...Object.keys(values),...Object.keys(data.values)])) {
          if(disputed.has(field)||!isDeepStrictEqual(values[field],data.values[field])) {
            disputed.add(field);delete values[field];
          }
        }
        old.data={...old.data,values,legacyConflictFields:[...disputed].sort()};
        old.sources.push(source);
        warnings.push({kind:'legacy-conflict-quarantined',path,fields:[...disputed].sort(),sources:[...old.sources]});
        return;
      }
      conflicts.push({kind:'canonical-collision',path,sources:[...old.sources,source]});
      return;
    }
    if(old) old.sources.push(source); else writes.set(path,{path,data,sources:[source]});
  }
  for(const site of collections.class_locations || []) {
    if(sites.has(site.data.name)) conflicts.push({kind:'duplicate-site-name',id:site.id});
    sites.set(site.data.name,site.id);
  }
  for(const student of collections.students || []) {
    const locationId=sites.get(student.data.classLocation);
    if(!locationId) {conflicts.push({kind:'unknown-student-site',id:student.id});continue;}
    put('students/'+student.id,{locationId,enrollmentRevision:1,
      enrollmentStartDate:cutoff,enrollmentStartKnown:false,archived:false},'students/'+student.id);
    put('student_enrollments/'+hash(['baseline',student.id,cutoff]).slice(0,40),{
      studentId:student.id,locationId,startDate:cutoff,endDateExclusive:'9999-12-31',
      startKnown:false,revision:1,source:'migrationBaseline',
    },'students/'+student.id);
    summaries.set(student.id,{name:student.data.name || '歷史學生',locationIds:new Set([locationId]),archived:false});
  }
  const evidence=new Map();
  for(const [legacy,kind,target] of [
    ['daily_attendance','attendance','attendance_records'],
    ['daily_performances','performance','performance_records'],
  ]) {
    for(const document of collections[legacy] || []) {
      const match=/^(\d{4})-?(\d{2})-?(\d{2})_(.+)$/.exec(document.id);
      if(!match) {conflicts.push({kind:'invalid-document-id',path:legacy+'/'+document.id});continue;}
      let d;
      try {d=dateKey([match[1],match[2],match[3]].join('-'));}
      catch {conflicts.push({kind:'invalid-date',path:legacy+'/'+document.id});continue;}
      const locationId=sites.get(match[4]);
      if(!locationId) {conflicts.push({kind:'unknown-history-site',path:legacy+'/'+document.id});continue;}
      const records=document.data.records;
      if(!Array.isArray(records)) {conflicts.push({kind:'invalid-records',path:legacy+'/'+document.id});continue;}
      put('class_sessions/'+[d,locationId].join('.'),{
        locationId,dateKey:d,status:'legacyUnverified',revision:1,
      },legacy+'/'+document.id);
      records.forEach((row,index)=>{
        const source=legacy+'/'+document.id+'#'+index;
        if(typeof row.sid!=='string'||!/^[a-zA-Z0-9_-]{1,128}$/.test(row.sid)) {
          conflicts.push({kind:'invalid-student-id',source});return;
        }
        const values={};
        const fields=kind==='attendance'?['status','leaveReason']:
          ['performanceRating','remarks','classPerformanceRating','mathPerformanceRating',
           'chinesePerformanceRating','englishPerformanceRating','socialPerformanceRating','excellentCharacters'];
        for(const key of fields) if(Object.hasOwn(row,key)) values[key]=row[key];
        if(kind==='attendance' && (values.leaveReason==null || values.leaveReason==='')) values.leaveReason='';
        if(kind==='performance') {
          const tags=Array.isArray(values.excellentCharacters)?[...values.excellentCharacters]:[];
          if(row.homeworkCompleted===true&&!tags.includes('homeworkCompleted')) tags.push('homeworkCompleted');
          if(row.isHelper===true&&!tags.includes('helper')) tags.push('helper');
          if(tags.length) values.excellentCharacters=tags;
        }
        put(target+'/'+[d,locationId,row.sid].join('.'),{
          schemaVersion:2,studentId:row.sid,locationId,dateKey:d,enrollmentId:null,
          nameSnapshot:row.name || '歷史學生',revision:1,values,
          provenance:'legacyUnverified',
          ...(kind==='performance'?{awardActive:false,awardReviewRequired:true}:{}),
        },source);
        // Original documents are backed up unchanged; retain an explicit audit link.
        put('legacy_record_sources/'+hash(source),{
          source,sourceHash:hash(row),target:target+'/'+[d,locationId,row.sid].join('.'),
          raw:row,
        },source);
        if(!summaries.has(row.sid)) {
          summaries.set(row.sid,{name:row.name || '歷史學生',locationIds:new Set(),archived:true});
          warnings.push({kind:'orphan-history',studentId:row.sid});
        }
        summaries.get(row.sid).locationIds.add(locationId);
        const key=[d,locationId].join('.');
        if(!evidence.has(key)) evidence.set(key,new Set());
        evidence.get(key).add(row.sid);
      });
    }
  }
  for(const [sid,summary] of summaries) put('student_summaries/'+sid,{
    ...summary,locationIds:[...summary.locationIds].sort(),
  },'derived-summary');
  // Existing ribbon totals remain untouched; no replay of legacy excellent.
  return {schemaVersion:2,cutoff,sourceHash:hash(backup),sourceCounts,conflicts,warnings,
    dailyEvidence:Object.fromEntries([...evidence].map(([key,ids])=>[key,[...ids].sort()])),
    writes:[...writes.values()].sort((a,b)=>a.path.localeCompare(b.path))};
}
if(require.main===module) {
  const [input,cutoff,output]=process.argv.slice(2);
  if(!input||!cutoff||!output) throw Error('Usage: node roster-plan.cjs backup.json YYYY-MM-DD plan.json');
  const result=planMigration(JSON.parse(readFileSync(input,'utf8')),cutoff);
  writeFileSync(output,JSON.stringify(result,null,2));
  console.log(JSON.stringify({documents:result.writes.length,conflicts:result.conflicts.length,warnings:result.warnings.length}));
  if(result.conflicts.length) process.exitCode=2;
}
module.exports={planMigration};
