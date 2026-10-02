import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:uuid/uuid.dart';
import '../model/student/student_detail.dart';
import '../roster/roster_models.dart';
import '../roster/roster_repository.dart';
import '../roster/shared_stream_cache.dart';

/// Profile writes share the trusted command boundary. Attachments remain
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
  StudentDetail _parse(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return StudentDetail.fromJson({
      ...data,
      'id': doc.id,
      if (data['birthday'] is Timestamp)
        'birthday': (data['birthday'] as Timestamp).toDate()
    });
  }

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
            _cache.watch(
                '${access.uid}|${access.locationIds.join(',')}|$locationId',
                () => firestore
                    .collection('students')
                    .where('locationId', isEqualTo: locationId)
                    .snapshots(includeMetadataChanges: true)
                    .map((snapshot) => DataSnapshot(
                        snapshot.docs.map(_parse).toList(),
                        fromCache: snapshot.metadata.isFromCache)))
        ];
        return streams.first.combineLatestAll(streams.skip(1)).map((snapshots) {
          _students = snapshots.expand((snapshot) => snapshot.data).toList()
            ..sort((a, b) => a.id!.compareTo(b.id!));
          return List<StudentDetail>.unmodifiable(_students);
        });
      });
  Stream<StudentDetail?> watchById(String id) =>
      roster.watchAccess().switchMap((access) {
        if (access == null)
          return Stream<StudentDetail?>.error(StateError('學生資料存取權限尚未確認'));
        return firestore
            .collection('students')
            .doc(id)
            .snapshots()
            .map((doc) => doc.exists ? _parse(doc) : null);
      });
  Future<List<StudentDetail>> load() => watch().first;
  Future<StudentDetail?> getById(String id) => watchById(id).first;

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
      throw StateError('缺少學生識別、據點或入班日期');
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
      .update({'profileFileName': fileName});
  Future<void> updateAvatar(String id, String? fileName) =>
      firestore.collection('students').doc(id).update({'avatar': fileName});
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
