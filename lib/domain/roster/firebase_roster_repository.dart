import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stream_transform/stream_transform.dart';
import 'roster_models.dart';
import 'roster_repository.dart';
import 'roster_command_failure.dart';
import 'shared_stream_cache.dart';
import 'firebase_roster_commands.dart';
import 'roster_commands.dart';

class FirebaseRosterRepository implements RosterRepository {
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  final RosterCommands commands;
  final _cache = SharedStreamCache<List<Map<String, dynamic>>>();
  final _accessEvents = StreamController<RosterAccess?>.broadcast(sync: true);
  late final StreamSubscription<User?> _authSubscription;
  StreamSubscription<Object?>? _permissionSubscription;
  RosterAccess? _access;
  bool _initialized = false;
  int _identityGeneration = 0;
  int _permissionGeneration = 0;

  FirebaseRosterRepository(this.firestore, this.auth)
      : commands = RosterCommands(FirebaseRosterCommandStore(firestore)) {
    _authSubscription = auth
        .authStateChanges()
        .listen(_onIdentity, onError: _accessEvents.addError);
  }

  Future<void> _onIdentity(User? user) async {
    final generation = ++_identityGeneration;
    _access = null;
    _initialized = true;
    _accessEvents.add(null);
    await _permissionSubscription?.cancel();
    await _cache.clear();
    if (generation != _identityGeneration || user == null) return;
    final staff = firestore
        .collection('staff_access')
        .doc(user.uid)
        .snapshots(includeMetadataChanges: true);
    final config = firestore
        .collection('app_config')
        .doc('roster')
        .snapshots(includeMetadataChanges: true);
    _permissionSubscription = staff
        .combineLatest(config, (a, b) => [a, b])
        .asyncMap((documents) async {
      if (generation != _identityGeneration) return;
      final data = documents[0].data();
      if (documents.any((doc) => doc.metadata.isFromCache) && _access != null) {
        // An already verified session can keep editing offline drafts.
        // Initial authorization still requires a server-confirmed permission.
        return;
      }
      // Cached permissions alone never enable sensitive views.
      final valid = !documents.any((doc) => doc.metadata.isFromCache) &&
          data?['active'] == true &&
          ['teacher', 'manager', 'owner'].contains(data?['role']);
      final next = valid
          ? RosterAccess(user.uid, data!['role'] as String,
              List<String>.from(data['locationIds'] as List? ?? []),
              enabled: documents[1].data()?['status'] == 'enabled' &&
                  documents[1].data()?['clientWritesEnabled'] == true)
          : null;
      if (next != null &&
          _access != null &&
          next.uid == _access!.uid &&
          next.role == _access!.role &&
          next.enabled == _access!.enabled &&
          next.locationIds.join('|') == _access!.locationIds.join('|')) {
        return;
      }
      _access = null;
      _accessEvents.add(null);
      await _cache.clear();
      if (generation != _identityGeneration) return;
      _permissionGeneration++;
      _access = next;
      _accessEvents.add(next);
    }).listen((_) {}, onError: (Object error, StackTrace stack) {
      _access = null;
      _cache.clear();
      _accessEvents.add(null);
      _accessEvents.addError(error, stack);
    });
  }

  @override
  Stream<RosterAccess?> watchAccess() => Stream.multi((out) {
        final subscription = _accessEvents.stream.listen(out.addSync,
            onError: out.addErrorSync, onDone: out.closeSync);
        if (_initialized) out.addSync(_access);
        out.onCancel = subscription.cancel;
      });

  Stream<DataSnapshot<List<Map<String, dynamic>>>> _query(String key,
          String? locationId, Query<Map<String, dynamic>> Function() query) =>
      watchAccess().switchMap((access) {
        if (access == null ||
            (locationId != null && !access.locationIds.contains(locationId))) {
          return Stream.error(StateError('尚未取得此據點的存取權限'));
        }
        final scopedKey = [access.uid, _permissionGeneration, key].join('|');
        return _cache.watch(
            scopedKey,
            () => query()
                .snapshots(includeMetadataChanges: true)
                .map((snapshot) => DataSnapshot(
                    snapshot.docs
                        .map((doc) => {
                              ...doc.data(),
                              '_documentId': doc.id,
                            })
                        .toList(),
                    fromCache: snapshot.metadata.isFromCache)));
      });

  @override
  Stream<List<ClassSite>> watchSites() => watchAccess().switchMap((access) {
        if (access == null) return Stream.value(<ClassSite>[]);
        final ids = access.locationIds;
        if (ids.isEmpty) return Stream.value(<ClassSite>[]);
        final streams = <Stream<DataSnapshot<List<Map<String, dynamic>>>>>[];
        for (var i = 0; i < ids.length; i += 10) {
          final chunk = ids.skip(i).take(10).toList();
          streams.add(_query(
              'sites:${chunk.join(',')}',
              null,
              () => firestore
                  .collection('class_locations')
                  .where(FieldPath.documentId, whereIn: chunk)));
        }
        return streams.first
            .combineLatestAll(streams.skip(1))
            .map((results) => results
                .expand((snapshot) => snapshot.data)
                .map((data) => ClassSite(
                      data['_documentId'] as String,
                      data['name'] as String,
                      order: data['order'] as int? ?? 0,
                      active: data['active'] != false,
                    ))
                .toList()
              ..sort((a, b) => a.order.compareTo(b.order)));
      });

  @override
  Stream<DataSnapshot<List<StudentSummary>>> watchStudents(String locationId) =>
      _query(
          'students:$locationId',
          locationId,
          () => firestore.collection('student_summaries').where('locationIds',
              arrayContains: locationId)).map((snapshot) => DataSnapshot(
          snapshot.data
              .map(
                  (data) => StudentSummary(data['_documentId'] as String, data['name'] as String, archived: data['archived'] == true))
              .toList(),
          fromCache: snapshot.fromCache));

  @override
  Stream<DataSnapshot<List<Enrollment>>> watchEnrollments(String locationId,
          {BusinessDate? date, String? studentId}) =>
      _query(['enrollments', locationId, date, studentId].join(':'), locationId,
          () {
        Query<Map<String, dynamic>> query = firestore
            .collection('student_enrollments')
            .where('locationId', isEqualTo: locationId);
        if (date != null) {
          query = query
              .where('startDate', isLessThanOrEqualTo: date.value)
              .where('endDateExclusive', isGreaterThan: date.value);
        }
        if (studentId != null) {
          query = query.where('studentId', isEqualTo: studentId);
        }
        return query;
      }).map((snapshot) => DataSnapshot(
          snapshot.data
              .map((data) =>
                  Enrollment.fromJson(data['_documentId'] as String, data))
              .toList(),
          fromCache: snapshot.fromCache));

  @override
  Stream<DataSnapshot<List<DailyRecord>>> watchRecords(
          String kind, String locationId,
          {BusinessDate? date,
          String? studentId,
          BusinessDate? from,
          BusinessDate? to,
          int limit = 100,
          String? beforeDate}) =>
      _query(
          [kind, locationId, date, studentId, from, to, limit, beforeDate]
              .join(':'),
          locationId, () {
        if (!{'attendance', 'performance'}.contains(kind)) {
          throw ArgumentError.value(kind, 'kind');
        }
        Query<Map<String, dynamic>> query = firestore
            .collection(kind == 'attendance'
                ? 'attendance_records'
                : 'performance_records')
            .where('locationId', isEqualTo: locationId);
        if (date != null) return query.where('dateKey', isEqualTo: date.value);
        if (studentId != null) {
          query = query.where('studentId', isEqualTo: studentId);
        }
        if (from != null) {
          query = query.where('dateKey', isGreaterThanOrEqualTo: from.value);
        }
        if (to != null) {
          query = query.where('dateKey', isLessThanOrEqualTo: to.value);
        }
        if (beforeDate != null) {
          query = query.where('dateKey', isLessThan: beforeDate);
        }
        return query.orderBy('dateKey', descending: true).limit(limit);
      }).map((snapshot) => DataSnapshot(
          snapshot.data
              .map((data) => DailyRecord.fromJson(kind, data))
              .toList(),
          fromCache: snapshot.fromCache));

  @override
  Stream<DataSnapshot<List<ClassSession>>> watchSessions(
          String locationId, BusinessDate from, BusinessDate to) =>
      _query(
          ['sessions', locationId, from, to].join(':'),
          locationId,
          () => firestore
              .collection('class_sessions')
              .where('locationId', isEqualTo: locationId)
              .where('dateKey', isGreaterThanOrEqualTo: from.value)
              .where('dateKey', isLessThanOrEqualTo: to.value)).map(
          (snapshot) => DataSnapshot(
              snapshot.data
                  .map((data) => ClassSession(locationId, BusinessDate(data['dateKey'] as String), SessionStatus.values.byName(data['status'] as String), revision: data['revision'] as int? ?? 0))
                  .toList(),
              fromCache: snapshot.fromCache));

  @override
  Future<Map<String, dynamic>> command(Map<String, dynamic> payload) async {
    final access = _access;
    if (access == null) throw const RosterCommandFailure('permission-denied');
    // The transaction checks the maintenance gate after looking for a receipt.
    // A disabled UI must still be able to confirm an already committed retry.
    final Map<String, dynamic> result;
    try {
      result = await commands.execute(access.uid, payload);
    } on FirebaseException catch (error) {
      throw RosterCommandFailure(error.code);
    }
    if (_access?.uid != access.uid) throw StateError('帳號已切換，請重新確認儲存結果');
    return result;
  }

  Future<void> dispose() async {
    _identityGeneration++;
    await _authSubscription.cancel();
    await _permissionSubscription?.cancel();
    await _cache.clear();
    await _accessEvents.close();
  }
}
