'use strict';
const {createHash} = require('node:crypto');
const {isDeepStrictEqual} = require('node:util');
const {FieldValue,Timestamp} = require('firebase-admin/firestore');

class DomainError extends Error {
  constructor(code, message, details) { super(message); this.code = code; this.details = details; }
}
const fail = (code, message, details) => { throw new DomainError(code, message, details); };
const requireThat = (value, message) => {
  if (!value) fail('invalid-argument', message);
};
const id = value => {
  requireThat(typeof value === 'string' && /^[a-zA-Z0-9_-]{1,128}$/.test(value), '識別碼無效');
  return value;
};
const date = value => {
  requireThat(typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value) &&
    !Number.isNaN(Date.parse(value)) && new Date(value).toISOString().slice(0,10) === value,
    '日期無效');
  return value;
};
function stable(value) {
  if (Array.isArray(value)) return value.map(stable);
  if (value && typeof value === 'object') return Object.fromEntries(
    Object.keys(value).sort().map(key => [key, stable(value[key])]));
  return value;
}
const digest = value => createHash('sha256').update(JSON.stringify(stable(value))).digest('hex');
const dayAt = clock => new Date(clock().getTime() + 8 * 3600000).toISOString().slice(0,10);
const validStatuses = new Set(['attend', 'absent', 'leave', 'late', 'earlyLeave', 'busAbsent', null]);
const ratingFields = ['classPerformanceRating','mathPerformanceRating','chinesePerformanceRating',
  'englishPerformanceRating','socialPerformanceRating'];
const attendanceFields = ['status','leaveReason'];
const performanceFields = ['performanceRating','remarks','excellentCharacters',...ratingFields];
const profileFields = ['name','gender','phone','birthday','idNumber','school','email',
  'economicStatus','guardianName','guardianIdNumber','guardianCompany','guardianPhone',
  'guardianEmail','emergencyContactName','emergencyContactIdNumber','emergencyContactCompany',
  'emergencyContactPhone','emergencyContactEmail','description','hasSpecialDisease',
  'specialDiseaseDescription','isSpecialStudent','specialStudentDescription','needsPickup',
  'pickupRequirementDescription','familyStatus','ethnicStatus','interest','abilityEvaluation',
  'learningGoals','resourcesAndScholarships','talentClass','specialCourse','studentIntroduction','motto'];
function validateProfile(patch) {
  requireThat(patch && typeof patch==='object' && !Array.isArray(patch) &&
    Object.keys(patch).every(key=>profileFields.includes(key)), '學生欄位無效');
  for(const [key,value] of Object.entries(patch)) {
    if(['hasSpecialDisease','isSpecialStudent','needsPickup'].includes(key)) {
      requireThat(typeof value==='boolean','學生選項無效');
    } else if(['economicStatus','familyStatus','ethnicStatus'].includes(key)) {
      requireThat(Number.isInteger(value) && value>=0 && value<=20,'學生分類無效');
    } else if(key==='birthday') {
      requireThat(typeof value==='string' && !Number.isNaN(Date.parse(value)),'生日無效');
    } else {
      requireThat(value===null || (typeof value==='string' && value.length<=10000),'學生文字無效');
    }
  }
  if(Object.hasOwn(patch,'name')) requireThat(typeof patch.name==='string' &&
    patch.name.trim().length>0 && patch.name.length<=120,'姓名必填且不得超過 120 字');
}
function membershipProjection(periods,today) {
  const sorted=[...periods].sort((a,b)=>a.startDate.localeCompare(b.startDate));
  const active=sorted.filter(p=>p.startDate<=today && today<p.endDateExclusive);
  requireThat(active.length<=1,'就讀期間重疊，請先核對');
  const next=sorted.find(p=>p.startDate>today);
  const selected=active[0] || sorted.filter(p=>p.startDate<=today).at(-1) || next;
  requireThat(selected,'缺少就讀關係');
  const due=sorted.flatMap(p=>[p.startDate,p.endDateExclusive])
    .filter(d=>d>today && d<'9999-12-31').sort()[0] || '9999-12-31';
  return {locationId:selected.locationId,enrollmentStartDate:selected.startDate,
    enrollmentStartKnown:selected.startKnown!==false,
    archived:active.length===0 && sorted.some(p=>p.startDate<=today),projectionDueDate:due};
}
function validatePatch(kind, patch) {
  requireThat(patch && !Array.isArray(patch) && typeof patch === 'object', '修改內容無效');
  const allowed = kind === 'attendance' ? attendanceFields : performanceFields;
  requireThat(Object.keys(patch).length > 0 &&
    Object.keys(patch).every(key => allowed.includes(key)), '包含不允許修改的欄位');
  for (const [key, value] of Object.entries(patch)) {
    if (key === 'status') requireThat(validStatuses.has(value), '出席狀態無效');
    else if (key === 'performanceRating') requireThat(
      [null,'excellent','good','average','poor','terrible'].includes(value), '整體表現無效');
    else if (ratingFields.includes(key)) requireThat(
      value === null || (Number.isInteger(value) && value >= 1 && value <= 5), '分數須為 1 至 5');
    else if (key === 'excellentCharacters') requireThat(Array.isArray(value) &&
      value.length <= 30 && value.every(v => typeof v === 'string' && v.length <= 80), '品格標籤無效');
    else requireThat(typeof value === 'string' && value.length <= 4000, '文字過長或格式無效');
  }
}
function mergeValues(current, base, patch) {
  const fields = new Set(Object.keys(patch));
  if (fields.has('status') || fields.has('leaveReason')) {
    fields.add('status'); fields.add('leaveReason');
  }
  const conflicts = [...fields].filter(key => {
    const desired = Object.hasOwn(patch,key) ? patch[key] : base[key];
    return !isDeepStrictEqual(current[key] ?? null, base[key] ?? null) &&
      !isDeepStrictEqual(current[key] ?? null, desired ?? null);
  });
  if (conflicts.length) fail('aborted','同一欄位已被修改，請核對後重試',{fields:conflicts});
  const merged = {...current,...patch};
  if (Object.hasOwn(patch,'status') && patch.status !== 'leave') merged.leaveReason = '';
  return merged;
}
function scope(access, locationId, manager = false) {
  if (!access || access.active !== true ||
      !['teacher','manager','owner'].includes(access.role) ||
      (manager && !['manager','owner'].includes(access.role)) ||
      !(access.locationIds || []).includes(locationId)) {
    fail('permission-denied','沒有這個據點的操作權限');
  }
}
function createRosterService(db, clock = () => new Date()) {
  const ref = (collection, key) => db.collection(collection).doc(key);
  async function execute(uid, input) {
    requireThat(input && typeof input === 'object', '請求格式無效');
    const opId = id(input.operationId);
    const hash = digest(input);
    return db.runTransaction(async tx => {
      const [accessDoc, configDoc, operationDoc] = await Promise.all([
        tx.get(ref('staff_access',uid)), tx.get(ref('app_config','roster')),
        tx.get(ref('record_operations',opId)),
      ]);
      const access = accessDoc.data();
      if (!access || !access.active) fail('permission-denied','帳號未獲工作人員授權');
      if (operationDoc.exists) {
        const previous = operationDoc.data();
        if (previous.uid !== uid || previous.hash !== hash) {
          fail('already-exists','操作識別碼已用於不同內容');
        }
        for(const locationId of previous.locationIds || []) scope(access,locationId);
        return previous.result;
      }
      if (configDoc.data()?.status !== 'enabled') {
        fail('failed-precondition','資料維護中，請保留修改稍後再試');
      }
      let result;
      if (input.action === 'saveRecord') result = await saveRecord(tx, access, uid, input);
      else if (input.action === 'setSession') result = await setSession(tx, access, uid, input);
      else if (input.action === 'enrollStudent') result = await enroll(tx, access, uid, input);
      else if (input.action === 'changeEnrollment') result = await changeEnrollment(tx, access, uid, input);
      else if (input.action === 'updateProfile') result = await updateProfile(tx, access, uid, input);
      else if (input.action === 'correctEnrollment') result = await correctEnrollment(tx, access, uid, input);
      else if (input.action === 'redeemRibbon') result = await redeem(tx, access, uid, input);
      else fail('invalid-argument','不支援的操作');
      tx.create(ref('record_operations',opId), {
        uid, hash, action: input.action, result,
        locationIds: result.locationIds || (input.locationId?[input.locationId]:[]),
        createdAt: FieldValue.serverTimestamp(),
      });
      return result;
    });
  }
  async function saveRecord(tx, access, uid, input) {
    const {kind, patch, base = {}} = input;
    requireThat(['attendance','performance'].includes(kind), '紀錄類型無效');
    const sid = id(input.studentId), locationId = id(input.locationId), d = date(input.dateKey);
    scope(access,locationId);
    requireThat(d <= dayAt(clock), '尚未上課的日期不能預先點名或評分');
    validatePatch(kind,patch);
    requireThat(base && typeof base === 'object' && !Array.isArray(base), '基準資料無效');
    const recordId = [d,locationId,sid].join('.');
    const recordRef = ref(kind === 'attendance' ? 'attendance_records' : 'performance_records',recordId);
    const sessionRef = ref('class_sessions',[d,locationId].join('.'));
    const enrollmentRef = input.enrollmentId ? ref('student_enrollments',id(input.enrollmentId)) : null;
    const [oldDoc, studentDoc, sessionDoc, enrollmentDoc, countDoc] = await Promise.all([
      tx.get(recordRef), tx.get(ref('students',sid)), tx.get(sessionRef),
      enrollmentRef ? tx.get(enrollmentRef) : Promise.resolve(null),
      kind === 'performance' ? tx.get(ref('yellow_ribbon_counts',sid)) : Promise.resolve(null),
    ]);
    const enrollment = enrollmentDoc?.data(), old = oldDoc.data();
    const valid = enrollment && enrollment.studentId === sid &&
      enrollment.locationId === locationId && enrollment.startDate <= d && d < enrollment.endDateExclusive;
    if (!valid) {
      scope(access,locationId,true);
      requireThat(old && typeof input.correctionReason === 'string' &&
        input.correctionReason.trim().length >= 3 && input.correctionReason.length <= 4000, '歷史名冊異常，需管理者附理由核對');
    }
    requireThat(studentDoc.exists || old, '找不到學生');
    if (sessionDoc.data()?.status === 'cancelled') fail('failed-precondition','該日已取消上課，請先確認課次');
    const current = old?.values || {};
    const values = mergeValues(current,base,patch);
    // Validate only submitted fields. Legacy unknown fields remain untouched and
    // auditable; editing a remark must not discard an old homework/tag payload.
    const revision = (old?.revision || 0) + 1;
    const confirmedFields=[...new Set([...(old?.confirmedFields || []),...Object.keys(patch)])];
    const provenance=!old || old.provenance==='confirmed' ||
      (kind==='attendance' ? confirmedFields.includes('status'):
        performanceFields.filter(key=>values[key]!=null).every(key=>confirmedFields.includes(key)))?
      'confirmed':'partiallyConfirmed';
    let awardActive = old?.awardActive === true;
    let awardReviewRequired = old?.awardReviewRequired === true;
    if (kind === 'performance') {
      const excellent = values.performanceRating === 'excellent';
      const wasExcellent = current.performanceRating === 'excellent';
      const delta = excellent && !wasExcellent ? 1 : !excellent && wasExcellent && awardActive ? -1 : 0;
      if (!excellent && wasExcellent && !awardActive) awardReviewRequired = true;
      if (delta) {
        awardActive = delta > 0;
        tx.set(ref('yellow_ribbon_counts',sid), {
          totalCount: (countDoc.data()?.totalCount || 0) + delta,
          usedCount: countDoc.data()?.usedCount || 0,
          lastUpdated: FieldValue.serverTimestamp(),
        },{merge:true});
        tx.create(ref('ribbon_events',input.operationId), {
          studentId:sid, locationId, recordId, delta, kind:delta > 0 ? 'award' : 'reversal',
          updatedBy:uid, createdAt:FieldValue.serverTimestamp(),
        });
      }
    }
    const next = {
      schemaVersion:2, studentId:sid, locationId, dateKey:d,
      enrollmentId: valid ? enrollmentRef.id : null,
      nameSnapshot:studentDoc.data()?.name || old?.nameSnapshot || '歷史學生',
      revision, values, provenance,confirmedFields, updatedBy:uid,
      updatedAt:FieldValue.serverTimestamp(), lastOperationId:input.operationId,
      ...(kind === 'performance' ? {awardActive,awardReviewRequired} : {}),
      ...(input.correctionReason ? {correctionReason:input.correctionReason} : {}),
    };
    tx.set(recordRef,next,{merge:true});
    if (kind === 'attendance' && values.status != null) {
      if (sessionDoc.data()?.status === 'cancelled') {
        fail('failed-precondition','該日已取消上課，請先確認課次');
      }
      if (sessionDoc.data()?.status !== 'held') tx.set(sessionRef, {
        locationId,dateKey:d,status:'held',revision:(sessionDoc.data()?.revision || 0)+1,
        updatedBy:uid,updatedAt:FieldValue.serverTimestamp(),
      },{merge:true});
    }
    return {recordId,revision,values,provenance,confirmedFields,awardReviewRequired};
  }
  async function setSession(tx, access, uid, input) {
    const locationId = id(input.locationId), d = date(input.dateKey);
    scope(access,locationId,input.status === 'cancelled');
    requireThat(['held','cancelled'].includes(input.status) && d <= dayAt(clock),'課次狀態或日期無效');
    if (input.status === 'cancelled') requireThat(
      typeof input.reason === 'string' && input.reason.trim().length >= 3 && input.reason.length <= 400,'取消上課須填理由');
    const target = ref('class_sessions',[d,locationId].join('.'));
    const old = await tx.get(target);
    if ((old.data()?.revision || 0) !== input.expectedRevision) fail('aborted','課次已被修改');
    tx.set(target,{locationId,dateKey:d,status:input.status,reason:input.reason || '',
      revision:(old.data()?.revision || 0)+1,updatedBy:uid,
      updatedAt:FieldValue.serverTimestamp()});
    return {sessionId:target.id,revision:(old.data()?.revision || 0)+1};
  }
  async function enroll(tx, access, uid, input) {
    const sid = id(input.studentId), locationId = id(input.locationId), start = date(input.startDate);
    scope(access,locationId,true);
    validateProfile(input.profile);
    requireThat(input.profile.name,'姓名必填');
    requireThat(Buffer.byteLength(JSON.stringify(input.profile)) <= 100000,'學生資料過大');
    const [student,site] = await Promise.all([
      tx.get(ref('students',sid)),tx.get(ref('class_locations',locationId)),
    ]);
    requireThat(!student.exists,'學生已存在，請使用轉點或重新入班');
    requireThat(site.exists && site.data().active !== false,'據點不存在或已停用');
    const enrollmentId = input.operationId;
    tx.create(ref('students',sid),{
      ...input.profile,...(input.profile.birthday?{birthday:Timestamp.fromDate(new Date(input.profile.birthday))}:{}),
      id:sid,classLocation:site.data().name,locationId,
      archived:false,enrollmentRevision:1,revision:1,enrollmentStartDate:start,
      projectionDueDate:start>dayAt(clock)?start:'9999-12-31',
      createdAt:FieldValue.serverTimestamp(),updatedAt:FieldValue.serverTimestamp(),
      updatedBy:uid,
    });
    tx.create(ref('student_enrollments',enrollmentId),{
      studentId:sid,locationId,startDate:start,endDateExclusive:'9999-12-31',
      startKnown:true,revision:1,source:'enrollment',updatedBy:uid,
      updatedAt:FieldValue.serverTimestamp(),
    });
    tx.create(ref('student_summaries',sid),{
      name:input.profile.name,locationIds:[locationId],archived:false,
    });
    return {studentId:sid,enrollmentId,revision:1,locationIds:[locationId]};
  }
  async function updateProfile(tx,access,uid,input) {
    requireThat(input.base && typeof input.base==='object' && !Array.isArray(input.base),'基準資料無效');
    const sid=id(input.studentId),target=ref('students',sid);
    const oldDoc=await tx.get(target);
    requireThat(oldDoc.exists,'找不到學生');
    const old=oldDoc.data();scope(access,old.locationId);
    validateProfile(input.patch);
    requireThat(Object.keys(input.patch).length>0,'沒有修改');
    const current=Object.fromEntries(profileFields.map(key=>[key,
      old[key] instanceof Timestamp?old[key].toDate().toISOString():old[key]??null]));
    const merged=mergeValues(current,input.base || {},input.patch);
    const changes=Object.fromEntries(Object.keys(input.patch).map(key=>[key,
      key==='birthday'?Timestamp.fromDate(new Date(merged[key])):merged[key]]));
    const revision=(old.revision || 0)+1;
    tx.update(target,{...changes,revision,updatedBy:uid,updatedAt:FieldValue.serverTimestamp()});
    if(Object.hasOwn(changes,'name')) tx.update(ref('student_summaries',sid),{name:changes.name});
    return {studentId:sid,revision,values:merged,locationIds:[old.locationId]};
  }
  async function changeEnrollment(tx, access, uid, input) {
    const sid = id(input.studentId), d = date(input.effectiveDate);
    requireThat(['transfer','archive','reenroll'].includes(input.mode),'就讀異動類型無效');
    const studentRef = ref('students',sid);
    const studentDoc = await tx.get(studentRef);
    requireThat(studentDoc.exists,'找不到學生');
    const student = studentDoc.data();
    if ((student.enrollmentRevision || 0) !== input.expectedRevision) fail('aborted','就讀關係已被修改');
    const periods = await tx.get(db.collection('student_enrollments').where('studentId','==',sid));
    const active = periods.docs.filter(p => p.data().startDate <= d && d < p.data().endDateExclusive);
    requireThat(active.length <= 1,'就讀期間重疊，請先核對');
    const old = active[0];
    const locationId = input.mode === 'archive' ? old?.data().locationId : id(input.locationId);
    requireThat(locationId,'指定日期沒有有效就讀關係');
    scope(access,locationId,true);
    if (old) scope(access,old.data().locationId,true);
    if (input.mode === 'reenroll') requireThat(!old,'指定日期已在班');
    else requireThat(old,'指定日期沒有有效就讀關係');
    const later = periods.docs.some(p => p.id !== old?.id && p.data().endDateExclusive > d);
    requireThat(!later,'已有其他現在或未來就讀期間，請先核對');
    const site = await tx.get(ref('class_locations',locationId));
    requireThat(site.exists && site.data().active !== false,'據點不存在或已停用');
    const revision = (student.enrollmentRevision || 0)+1;
    const nextPeriods=periods.docs.map(p=>p.id===old?.id?{...p.data(),endDateExclusive:d}:p.data());
    if(input.mode!=='archive') nextPeriods.push({locationId,startDate:d,endDateExclusive:'9999-12-31'});
    const projection=membershipProjection(nextPeriods,dayAt(clock));
    const projectedSite=projection.locationId===locationId?site:
      await tx.get(ref('class_locations',projection.locationId));
    if (old) tx.update(old.ref,{endDateExclusive:d,revision:(old.data().revision || 0)+1,
      updatedAt:FieldValue.serverTimestamp(),updatedBy:uid});
    if (input.mode !== 'archive') tx.create(ref('student_enrollments',input.operationId),{
      studentId:sid,locationId,startDate:d,endDateExclusive:'9999-12-31',
      startKnown:true,revision:1,source:input.mode,updatedBy:uid,updatedAt:FieldValue.serverTimestamp(),
    });
    tx.set(ref('student_summaries',sid),{
      name:student.name,locationIds:FieldValue.arrayUnion(locationId),
      archived:projection.archived,
    },{merge:true});
    tx.update(studentRef,{
      enrollmentRevision:revision,updatedBy:uid,updatedAt:FieldValue.serverTimestamp(),
      ...projection,classLocation:projectedSite.data().name,
    });
    return {studentId:sid,revision,locationIds:[...new Set([locationId,old?.data().locationId].filter(Boolean))]};
  }
  async function correctEnrollment(tx,access,uid,input) {
    const sid=id(input.studentId),periodId=id(input.enrollmentId);
    const start=date(input.startDate),end=date(input.endDateExclusive);
    requireThat(start<end && typeof input.reason==='string' && input.reason.trim().length>=3,
      '更正就讀期間須填有效日期及核對理由');
    const studentRef=ref('students',sid),studentDoc=await tx.get(studentRef);
    requireThat(studentDoc.exists,'找不到學生');
    const student=studentDoc.data();
    requireThat(student.enrollmentRevision===input.expectedRevision,'就讀關係已變更');
    const periods=await tx.get(db.collection('student_enrollments').where('studentId','==',sid));
    const old=periods.docs.find(p=>p.id===periodId);requireThat(old,'找不到就讀期間');
    for(const p of periods.docs) scope(access,p.data().locationId,true);
    requireThat(!periods.docs.some(p=>p.id!==periodId && p.data().startDate<end &&
      p.data().endDateExclusive>start),'更正後與其他就讀期間重疊');
    const changed={...old.data(),startDate:start,endDateExclusive:end,startKnown:true};
    const projection=membershipProjection(periods.docs.map(p=>p.id===periodId?changed:p.data()),dayAt(clock));
    const site=await tx.get(ref('class_locations',projection.locationId));
    tx.update(old.ref,{startDate:start,endDateExclusive:end,startKnown:true,
      revision:(old.data().revision || 0)+1,correctionReason:input.reason,
      previousPeriod:{startDate:old.data().startDate,endDateExclusive:old.data().endDateExclusive},
      updatedBy:uid,updatedAt:FieldValue.serverTimestamp()});
    tx.update(studentRef,{...projection,classLocation:site.data().name,
      enrollmentRevision:student.enrollmentRevision+1,updatedBy:uid,updatedAt:FieldValue.serverTimestamp()});
    tx.update(ref('student_summaries',sid),{archived:projection.archived});
    return {studentId:sid,revision:student.enrollmentRevision+1,
      locationIds:[...new Set(periods.docs.map(p=>p.data().locationId))]};
  }
  async function applyDueMemberships() {
    const today=dayAt(clock);
    const due=await db.collection('students').where('projectionDueDate','<=',today).get();
    for(const doc of due.docs) await db.runTransaction(async tx=>{
      const student=await tx.get(doc.ref);
      if(student.data()?.projectionDueDate>today) return;
      const periods=await tx.get(db.collection('student_enrollments').where('studentId','==',doc.id));
      const projection=membershipProjection(periods.docs.map(p=>p.data()),today);
      const site=await tx.get(ref('class_locations',projection.locationId));
      tx.update(doc.ref,{...projection,classLocation:site.data().name,
        updatedBy:'system:membership-projection',updatedAt:FieldValue.serverTimestamp()});
      tx.update(ref('student_summaries',doc.id),{archived:projection.archived});
    });
    return due.size;
  }
  async function redeem(tx, access, uid, input) {
    const sid = id(input.studentId);
    const student = await tx.get(ref('students',sid));
    requireThat(student.exists,'找不到學生');
    scope(access,student.data().locationId);
    requireThat(Number.isInteger(input.amount) && input.amount > 0 && input.amount <= 10000,'兌換數量無效');
    const countRef = ref('yellow_ribbon_counts',sid), count = await tx.get(countRef);
    const total = count.data()?.totalCount || 0, used = count.data()?.usedCount || 0;
    requireThat(total-used >= input.amount,'可用緞帶不足');
    tx.set(countRef,{totalCount:total,usedCount:used+input.amount,lastUpdated:FieldValue.serverTimestamp()},{merge:true});
    tx.create(ref('ribbon_events',input.operationId),{
      studentId:sid,locationId:student.data().locationId,kind:'redemption',
      amount:input.amount,updatedBy:uid,createdAt:FieldValue.serverTimestamp(),
    });
    return {studentId:sid,totalCount:total,usedCount:used+input.amount,locationIds:[student.data().locationId]};
  }
  return {execute,applyDueMemberships};
}
module.exports = {createRosterService, DomainError, mergeValues, validatePatch, date, scope};
