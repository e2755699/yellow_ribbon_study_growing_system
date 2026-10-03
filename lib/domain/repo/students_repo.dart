import 'package:yellow_ribbon_study_growing_system/domain/utils/request_timeout.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:uuid/uuid.dart';
import '../model/student/student_detail.dart';
import '../roster/roster_models.dart';
import '../roster/roster_repository.dart';
import '../roster/shared_stream_cache.dart';
import '../roster/roster_commands.dart';
import '../roster/roster_command_failure.dart';

/// Authorization loss is distinct from a temporary profile stream failure.
class StudentProfileAccessDenied implements Exception {
  const StudentProfileAccessDenied();
}

/// Profile writes share the atomic client command boundary. Attachments remain
/// field-only writes so failed uploads can restore their previous link.
class StudentsRepo {
  final FirebaseFirestore firestore;
  final RosterRepository roster;
  final _cache = SharedStreamCache<List<StudentDetail>>();
  List<StudentDetail> _students = [];
  StudentsRepo({required this.roster, FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;
  StudentDetail getStudentDetail(String sid) =>
      _students.firstWhere((s) => s.id == sid);
  StudentDetail _parse(DocumentSnapshot<Map<String, dynamic>> doc, String day,
      Map<String, String> siteNames) {
    final data = doc.data()!;
    final projection = RosterCommands.membershipProjection(
        (data['enrollmentTimeline'] as List).map(RosterCommands.map).toList(),
        day);
    return StudentDetail.fromJson({
      ...data,
      ...projection,
      'classLocation':
          siteNames[projection['locationId']] ?? data['classLocation'],
      'id': doc.id,
      if (data['birthday'] is Timestamp)
        'birthday': (data['birthday'] as Timestamp).toDate()
    });
  }

  /// Re-evaluate scheduled memberships while a page remains open overnight.
  /// This is a local subscription clock; it never writes or schedules a backend job.
  static Stream<String> businessDays({DateTime Function()? clock}) =>
      Stream.multi((out) {
        Timer? timer;
        void emit() {
          final now = (clock ?? DateTime.now)().toUtc();
          final taiwan = now.add(const Duration(hours: 8));
          out.add(taiwan.toIso8601String().substring(0, 10));
          final next = DateTime.utc(taiwan.year, taiwan.month, taiwan.day + 1)
              .subtract(const Duration(hours: 8));
          timer = Timer(
              next.difference(now) + const Duration(milliseconds: 100), emit);
        }

        emit();
        out.onCancel = () => timer?.cancel();
      });

  Stream<DataSnapshot<List<StudentDetail>>> _profile(
          String sid, String day, Map<String, String> sites) =>
      firestore
          .collection('students')
          .doc(sid)
          .snapshots(includeMetadataChanges: true)
          .withInitialResponseTimeout(
              isReady: (snapshot) => !snapshot.metadata.isFromCache)
          // A historical summary is not permission to show cached profile data.
          .where((doc) => !doc.metadata.isFromCache)
          .map((doc) => DataSnapshot(
              doc.exists ? [_parse(doc, day, sites)] : <StudentDetail>[],
              fromCache: false))
          .transform(StreamTransformer.fromHandlers(
              handleError: (Object error, StackTrace stack, sink) {
        if (error is FirebaseException &&
            {'permission-denied', 'unauthenticated'}.contains(error.code)) {
          sink.add(const DataSnapshot(<StudentDetail>[], fromCache: false));
        } else {
          sink.addError(error, stack);
        }
      }));

  Stream<List<StudentDetail>> watch() =>
      roster.watchAccess().switchMap((access) {
        if (access == null) {
          _students = [];
          _cache.clear();
          return Stream<List<StudentDetail>>.error(StateError('學生資料存取權限尚未確認'));
        }
        if (access.locationIds.isEmpty) return Stream.value(<StudentDetail>[]);
        final streams = [
          for (final locationId in access.locationIds)
            firestore
                .collection('student_summaries')
                .where('locationIds', arrayContains: locationId)
                .snapshots()
                .withInitialResponseTimeout()
                .map((snapshot) => snapshot.docs
                    .map((doc) => {'id': doc.id, ...doc.data()})
                    .toList())
        ];
        return streams.first
            .combineLatestAll(streams.skip(1))
            .combineLatest(
                businessDays(), (rows, day) => (rows: rows, day: day))
            .combineLatest(
                roster.watchSites(),
                (state, sites) => (
                      rows: state.rows,
                      day: state.day,
                      sites: {for (final site in sites) site.id: site.name}
                    ))
            .switchMap((state) {
          final ids = <String>{};
          for (final summary in state.rows.expand((rows) => rows)) {
            final raw = summary['enrollmentTimeline'];
            if (raw is! List || raw.isEmpty) {
              continue; // Historical orphan summaries have no profile.
            }
            final projection = RosterCommands.membershipProjection(
                raw.map(RosterCommands.map).toList(), state.day);
            if (access.locationIds.contains(projection['locationId'])) {
              ids.add(summary['id'] as String);
            }
          }
          if (ids.isEmpty) {
            _students = [];
            return Stream.value(<StudentDetail>[]);
          }
          final profiles = [
            for (final sid in ids)
              _cache
                  .watch(
                      '${access.uid}|${access.locationIds.join(',')}|${state.day}|$sid|${state.sites}',
                      () => _profile(sid, state.day, state.sites))
                  .where((snapshot) => !snapshot.fromCache)
          ];
          return profiles.first
              .combineLatestAll(profiles.skip(1))
              .map((snapshots) {
            _students = snapshots.expand((s) => s.data).toList()
              ..sort((a, b) => a.id!.compareTo(b.id!));
            return List<StudentDetail>.unmodifiable(_students);
          });
        });
      });
  Stream<StudentDetail?> watchById(String id) =>
      roster.watchAccess().switchMap((access) {
        if (access == null) {
          return Stream<StudentDetail?>.error(
              const StudentProfileAccessDenied());
        }
        return businessDays()
            .combineLatest(
                roster.watchSites(),
                (day, sites) => (
                      day: day,
                      sites: {for (final site in sites) site.id: site.name}
                    ))
            .switchMap((state) => _profile(id, state.day, state.sites)
                .map((snapshot) => snapshot.data.firstOrNull));
      });
  Future<List<StudentDetail>> load() => watch().first.withRequestTimeout();
  Future<StudentDetail?> getById(String id) =>
      watchById(id).first.withRequestTimeout();

  static Map<String, dynamic> profileValues(StudentDetail detail) {
    final data = detail.toJson();
    for (final key in [
      'id',
      'classLocation',
      'locationId',
      'enrollmentStartDate',
      'enrollmentRevision',
      'revision',
      'archived',
      'enrollmentStartKnown',
      'avatar',
      'profileFileName'
    ]) {
      data.remove(key);
    }
    data['birthday'] = detail.birthday.toUtc().toIso8601String();
    return data;
  }

  Future<String?> create(StudentDetail student) async {
    final sid = student.id;
    if (sid == null ||
        student.locationId.isEmpty ||
        student.enrollmentStartDate == null) {
      throw const RosterCommandFailure('invalid-argument');
    }
    await roster.command({
      'action': 'enrollStudent',
      'operationId': 'enroll_$sid',
      'studentId': sid,
      'locationId': student.locationId,
      'startDate': student.enrollmentStartDate,
      'profile': profileValues(student)
    });
    return sid;
  }

  Future<void> update(String id, StudentDetail student,
      {StudentDetail? expected}) async {
    if (expected == null) throw StateError('缺少表單原始資料，請重新開啟');
    if (student.locationId != expected.locationId ||
        student.classLocation != expected.classLocation) {
      throw StateError('變更據點請使用就讀異動');
    }
    final base = profileValues(expected), next = profileValues(student);
    final patch = {
      for (final entry in next.entries)
        if (!const DeepCollectionEquality()
            .equals(base[entry.key], entry.value))
          entry.key: entry.value
    };
    if (patch.isEmpty) return;
    final persisted = expected.persistedProfile;
    final remoteBase = persisted == null
        ? base
        : {
            for (final key in base.keys)
              key: persisted[key] is DateTime
                  ? (persisted[key] as DateTime).toUtc().toIso8601String()
                  : persisted[key]
          };
    await roster.command({
      'action': 'updateProfile',
      'operationId': const Uuid().v4(),
      'studentId': id,
      'base': remoteBase,
      'patch': patch
    });
  }

  Future<void> updateProfileFile(String id, String? fileName) => firestore
      .collection('students')
      .doc(id)
      .update({'profileFileName': fileName}).withRequestTimeout();
  Future<void> updateAvatar(String id, String? fileName) => firestore
      .collection('students')
      .doc(id)
      .update({'avatar': fileName}).withRequestTimeout();
  Future<void> changeEnrollment(StudentDetail student,
      {required String mode,
      required BusinessDate date,
      String? locationId}) async {
    await roster.command({
      'action': 'changeEnrollment',
      'operationId': const Uuid().v4(),
      'studentId': student.id,
      'mode': mode,
      'effectiveDate': date.value,
      'locationId': locationId,
      'expectedRevision': student.enrollmentRevision
    });
  }

  Future<void> delete(String id) async {
    final student = await getById(id);
    if (student == null) throw StateError('找不到學生');
    await changeEnrollment(student,
        mode: 'archive', date: BusinessDate.today());
  }
}
