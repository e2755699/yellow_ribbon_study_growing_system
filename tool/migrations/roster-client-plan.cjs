'use strict';
// ROSTER-A2.1: offline, deterministic metadata preparation. No SDK/network.
const {createHash} = require('node:crypto');
const {isDeepStrictEqual: equal} = require('node:util');
const hash = value => createHash('sha256').update(JSON.stringify(value)).digest('hex');
const safeId = value => typeof value === 'string' && /^[A-Za-z0-9_-]{1,128}$/.test(value);
const map = value => value && typeof value === 'object' && !Array.isArray(value);
const validDate = value => typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value)
  && !Number.isNaN(Date.parse(value)) && new Date(value).toISOString().slice(0,10) === value;
const guardedCollections = new Set(['students','student_enrollments','student_summaries',
  'yellow_ribbon_counts','membership_indexes','attendance_records','performance_records',
  'class_sessions','ribbon_events','record_operations','staff_access','class_locations',
  'daily_attendance','daily_performances','legacy_record_sources']);
const guardedPath = path => guardedCollections.has(path.split('/')[0]) || path === 'app_config/roster';
function documents(backup) {
  if (backup?.schemaVersion !== 1 || typeof backup.projectId !== 'string' || !map(backup.collections)) {
    throw Error('Expected complete typed roster-admin export');
  }
  const result = new Map();
  for (const [collection, rows] of Object.entries(backup.collections)) {
    if (!Array.isArray(rows) || collection.split('/').length % 2 !== 1) throw Error('Invalid backup collection');
    for (const row of rows) {
      const path = collection + '/' + row.id;
      if (typeof row.id !== 'string' || !row.id || row.id.includes('/') || !map(row.data) || result.has(path)) {
        throw Error('Invalid or duplicate backup document');
      }
      result.set(path, row.data);
    }
  }
  if (backup.documentCount !== result.size) throw Error('Backup document count mismatch');
  return result;
}
function requireFrozen(data) {
  if (data?.status !== 'maintenance' || data?.legacyWritesBlocked !== true || data?.clientWritesEnabled !== false) {
    throw Error('Requires maintenance, verified legacy write barrier and clientWritesEnabled:false');
  }
}
function planClientMetadata(backup) {
  const original = documents(backup), conflicts = [], warnings = [], writes = [];
  const rows = name => backup.collections[name] || [];
  const sites = new Set(rows('class_locations').map(row => row.id));
  const students = new Map(rows('students').map(row => [row.id,row.data]));
  const summaries = new Map(rows('student_summaries').map(row => [row.id,row.data]));
  const periods = new Map(), indexes = new Map([...sites].map(id => [id,{}]));
  const issue = (kind,path) => conflicts.push({kind,path});
  function put(path, patch) {
    const before = original.get(path);
    const after = {...before,...patch};
    // Conservative operational guard, not a promise to approach Firestore's limit.
    if (Buffer.byteLength(JSON.stringify(after),'utf8') > 700 * 1024) issue('document-capacity-review-required',path);
    if (!equal(before,after)) writes.push({path, data:patch, create:before === undefined});
  }
  for (const {id,data:p} of rows('student_enrollments')) {
    const path = 'student_enrollments/' + id;
    if (!safeId(id) || !safeId(p.studentId) || !safeId(p.locationId)
        || !students.has(p.studentId) || !sites.has(p.locationId)
        || !validDate(p.startDate) || !validDate(p.endDateExclusive)
        || p.startDate >= p.endDateExclusive || (p.startKnown !== undefined && typeof p.startKnown !== 'boolean')) {
      issue('invalid-or-orphan-enrollment',path); continue;
    }
    const entry = {studentId:p.studentId,locationId:p.locationId,startDate:p.startDate,endDateExclusive:p.endDateExclusive};
    indexes.get(p.locationId)[id] = entry;
    const timeline = periods.get(p.studentId) || [];
    timeline.push({id,...entry,startKnown:p.startKnown ?? true}); periods.set(p.studentId,timeline);
  }
  for (const [sid,student] of students) {
    if (!safeId(sid)) issue('invalid-student-id','students/' + sid);
    if (!summaries.has(sid)) issue('missing-protected-summary','students/' + sid);
    if (!(periods.get(sid)?.length)) issue('missing-enrollment-history','students/' + sid);
    for (const key of ['revision','enrollmentRevision']) {
      if (student[key] !== undefined && (!Number.isSafeInteger(student[key]) || student[key] < 0)) {
        issue('invalid-' + key,'students/' + sid);
      }
    }
  }
  for (const [sid,summary] of summaries) {
    if (!safeId(sid) || !Array.isArray(summary.locationIds) || !summary.locationIds.length
        || summary.locationIds.some(id => !safeId(id) || !sites.has(id))) {
      issue('invalid-summary-scope','student_summaries/' + sid); continue;
    }
    const timeline = (periods.get(sid) || []).sort((a,b) => a.startDate.localeCompare(b.startDate) || a.id.localeCompare(b.id));
    for (let i = 1; i < timeline.length; i++) {
      if (timeline[i-1].endDateExclusive > timeline[i].startDate) issue('overlapping-enrollments','students/' + sid);
    }
    // The summary is the existing protected historical wallet-read authority.
    const historySites = [...new Set([...summary.locationIds,...timeline.map(p => p.locationId)])].sort();
    const student = students.get(sid);
    if (student) {
      if (student.enrollmentTimeline !== undefined && !equal(student.enrollmentTimeline,timeline)) {
        issue('existing-timeline-disagrees','students/' + sid);
      }
      if (student.timelineSites !== undefined && (!Array.isArray(student.timelineSites)
          || !equal([...new Set(student.timelineSites)].sort(),historySites))) {
        issue('existing-timeline-scope-disagrees','students/' + sid);
      }
      put('students/' + sid, {enrollmentTimeline:timeline,timelineSites:historySites,
        revision:student.revision ?? 0,enrollmentRevision:student.enrollmentRevision ?? 0});
      if (summary.enrollmentTimeline !== undefined && !equal(summary.enrollmentTimeline,timeline)) {
        issue('existing-summary-timeline-disagrees','student_summaries/' + sid);
      }
    } else warnings.push({kind:'historical-summary-without-profile-preserved',path:'student_summaries/' + sid});
    put('student_summaries/' + sid,{locationIds:historySites,...(student ? {enrollmentTimeline:timeline} : {})});
    const count = original.get('yellow_ribbon_counts/' + sid);
    if (count && (!Number.isSafeInteger(count.totalCount) || count.totalCount < 0
        || !Number.isSafeInteger(count.usedCount) || count.usedCount < 0)) {
      issue('invalid-wallet-numbers','yellow_ribbon_counts/' + sid);
    }
    if (count?.locationIds !== undefined && (!Array.isArray(count.locationIds)
        || !equal([...new Set(count.locationIds)].sort(),historySites))) {
      issue('existing-wallet-scope-disagrees','yellow_ribbon_counts/' + sid);
    }
    // total may be below used after a legitimate award reversal; never recalculate it.
    put('yellow_ribbon_counts/' + sid, count ? {locationIds:historySites}
      : {totalCount:0,usedCount:0,locationIds:historySites});
  }
  for (const {id} of rows('yellow_ribbon_counts')) {
    if (!summaries.has(id)) issue('wallet-without-protected-summary','yellow_ribbon_counts/' + id);
  }
  for (const [loc,entries] of indexes) {
    if (!safeId(loc)) issue('invalid-site-id','class_locations/' + loc);
    // Until exemptions and capacity are reviewed, avoid nearing index/document limits.
    if (Object.keys(entries).length > 1000) issue('site-history-capacity-review-required','membership_indexes/' + loc);
    const previous = original.get('membership_indexes/' + loc);
    if (previous && (!map(previous.entries) || Object.keys(previous).some(k => !['entries','changedEnrollmentIds'].includes(k))
        || Object.entries(previous.entries).some(([id,p]) => !equal(p,entries[id])))) {
      issue('existing-membership-index-disagrees','membership_indexes/' + loc);
    }
    put('membership_indexes/' + loc,{entries,changedEnrollmentIds:[]});
  }
  for (const {id} of rows('membership_indexes')) {
    if (!sites.has(id)) issue('index-without-site','membership_indexes/' + id);
  }
  try { requireFrozen(original.get('app_config/roster')); }
  catch { warnings.push({kind:'preview-only-backup-not-frozen'}); }
  return {schemaVersion:1,taskId:'ROSTER-A2.1',projectId:backup.projectId,sourceHash:hash(backup),
    sourceDocumentCount:original.size,conflicts,warnings,writes:writes.sort((a,b) => a.path.localeCompare(b.path)),
    counts:{students:students.size,enrollments:rows('student_enrollments').length,
      historicalSummaries:summaries.size,sites:sites.size}};
}
module.exports = {planClientMetadata,documents,hash,guardedPath,requireFrozen};
