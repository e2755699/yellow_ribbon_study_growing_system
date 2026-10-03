import 'dart:async';
import '../model/roster/roster_models.dart';
import 'roster_repository.dart';
import '../model/roster/roster_command_failure.dart';

/// Deterministic offline adapter for tests and Widgetbook; never uses Firebase.
class MemoryRosterRepository implements RosterRepository {
  final events = StreamController<void>.broadcast(sync: true);
  RosterAccess? access;
  List<ClassSite> sites;
  List<StudentSummary> students;
  List<Enrollment> enrollments;
  List<DailyRecord> records;
  List<ClassSession> sessions;
  final commands = <Map<String, dynamic>>[];
  final receipts = <String, Map<String, dynamic>>{};
  final failStudents = <String>{};
  Completer<void>? saveGate;
  MemoryRosterRepository(
      {this.access,
      this.sites = const [],
      this.students = const [],
      this.enrollments = const [],
      this.records = const [],
      this.sessions = const []});
  void notify() => events.add(null);
  Stream<T> _watch<T>(T Function() value) => Stream.multi((out) {
        final sub = events.stream.listen((_) => out.addSync(value()));
        out.addSync(value());
        out.onCancel = sub.cancel;
      });
  @override
  Stream<RosterAccess?> watchAccess() => _watch(() => access).distinct((a, b) =>
      a?.uid == b?.uid &&
      a?.enabled == b?.enabled &&
      a?.role == b?.role &&
      a?.locationIds.join('|') == b?.locationIds.join('|'));
  @override
  Stream<List<ClassSite>> watchSites() => _watch(() => sites).distinct();
  @override
  Stream<DataSnapshot<List<StudentSummary>>> watchStudents(String locationId) =>
      _watch(() => DataSnapshot(students));
  @override
  Stream<DataSnapshot<List<Enrollment>>> watchEnrollments(String locationId,
          {BusinessDate? date, String? studentId}) =>
      _watch(() => DataSnapshot(enrollments
          .where((row) =>
              row.locationId == locationId &&
              (date == null || row.includes(date)) &&
              (studentId == null || row.studentId == studentId))
          .toList()));
  @override
  Stream<DataSnapshot<List<DailyRecord>>> watchRecords(String kind, String locationId,
          {BusinessDate? date,
          String? studentId,
          BusinessDate? from,
          BusinessDate? to,
          int limit = 100,
          String? beforeDate}) =>
      _watch(() => DataSnapshot(records
          .where((row) =>
              row.kind == kind &&
              row.locationId == locationId &&
              (date == null || row.date == date) &&
              (studentId == null || row.studentId == studentId) &&
              (from == null || row.date.compareTo(from) >= 0) &&
              (to == null || row.date.compareTo(to) <= 0) &&
              (beforeDate == null || row.date.value.compareTo(beforeDate) < 0))
          .toList()
        ..sort((a, b) => b.id.compareTo(a.id)))).map(
          (snapshot) => DataSnapshot(snapshot.data.take(date == null ? limit : records.length).toList()));
  @override
  Stream<DataSnapshot<List<ClassSession>>> watchSessions(
          String locationId, BusinessDate from, BusinessDate to) =>
      _watch(() => DataSnapshot(sessions
          .where((row) =>
              row.locationId == locationId &&
              row.date.compareTo(from) >= 0 &&
              row.date.compareTo(to) <= 0)
          .toList()));
  @override
  Future<Map<String, dynamic>> command(Map<String, dynamic> payload) async {
    commands.add(payload);
    if (payload['action'] == 'recoverOperation') {
      final original = payload['original'] as Map;
      final receipt = receipts[original['operationId']];
      if (receipt == null) {
        throw const RosterCommandFailure('failed-precondition');
      }
      return receipt;
    }
    final operationId = payload['operationId'] as String;
    if (receipts.containsKey(operationId)) return receipts[operationId]!;
    await saveGate?.future;
    if (payload['action'] == 'setSession') {
      final locationId = payload['locationId'] as String;
      final date = BusinessDate(payload['dateKey'] as String);
      final old = sessions
          .where((s) => s.locationId == locationId && s.date == date)
          .firstOrNull;
      if ((old?.revision ?? 0) != payload['expectedRevision']) {
        throw StateError('session conflict');
      }
      final next = ClassSession(locationId, date,
          SessionStatus.values.byName(payload['status'] as String),
          revision: (old?.revision ?? 0) + 1);
      sessions = [...sessions.where((s) => s.id != next.id), next];
      final result = {'sessionId': next.id, 'revision': next.revision};
      receipts[operationId] = result;
      notify();
      return result;
    }
    final batch = payload['action'] == 'saveRecords';
    final submitted = batch
        ? List<Map<String, dynamic>>.from((payload['records'] as List)
            .map((r) => Map<String, dynamic>.from(r as Map)))
        : [payload];
    final date = BusinessDate(payload['dateKey'] as String);
    final kind = payload['kind'] as String,
        locationId = payload['locationId'] as String;
    final session = sessions
        .where((s) => s.locationId == locationId && s.date == date)
        .firstOrNull;
    if (session?.status == SessionStatus.cancelled) {
      throw const RosterCommandFailure('failed-precondition');
    }
    final nextRecords = <DailyRecord>[];
    final results = <String, dynamic>{};
    // Stage all rows first: a rejection must not mutate records or receipts.
    for (final row in submitted) {
      final sid = row['studentId'] as String;
      if (failStudents.contains(sid))
        throw const RosterCommandFailure('invalid-argument');
      final enrollment = enrollments
          .where((e) =>
              e.id == row['enrollmentId'] &&
              e.studentId == sid &&
              e.locationId == locationId &&
              e.includes(date))
          .firstOrNull;
      if (enrollment == null)
        throw const RosterCommandFailure('failed-precondition');
      final old = records
          .where((r) =>
              r.studentId == sid &&
              r.date == date &&
              r.kind == kind &&
              r.locationId == locationId)
          .firstOrNull;
      final patch = Map<String, dynamic>.from(row['patch'] as Map);
      final values = <String, dynamic>{...?old?.values, ...patch};
      if (kind == 'attendance' &&
          patch.containsKey('status') &&
          patch['status'] != 'leave') values['leaveReason'] = '';
      final next = DailyRecord(kind,
          studentId: sid,
          locationId: locationId,
          date: date,
          enrollmentId: row['enrollmentId'] as String?,
          values: values,
          revision: (old?.revision ?? 0) + 1);
      nextRecords.add(next);
      results[sid] = {
        'values': values,
        'revision': next.revision,
        'recordId': next.id,
      };
    }
    records = [
      ...records.where(
          (r) => !nextRecords.any((n) => n.kind == r.kind && n.id == r.id)),
      ...nextRecords,
    ];
    if (kind == 'attendance' &&
        session?.status != SessionStatus.held &&
        nextRecords.any((r) => r.values['status'] != null)) {
      final held = ClassSession(locationId, date, SessionStatus.held,
          revision: (session?.revision ?? 0) + 1);
      sessions = [...sessions.where((s) => s.id != held.id), held];
    }
    final result = batch
        ? <String, dynamic>{
            'records': results,
            'locationIds': [locationId]
          }
        : Map<String, dynamic>.from(
            results[submitted.single['studentId']] as Map);
    receipts[operationId] = result;
    notify();
    return result;
  }

  Future<void> dispose() => events.close();
}
