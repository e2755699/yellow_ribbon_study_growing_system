// In-memory SDK interface doubles exercise the real repository without Firebase.
// ignore_for_file: subtype_of_sealed_class

import 'dart:async';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/utils/subscription_failure.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/firebase_roster_repository.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_models.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/shared_stream_cache.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/student_history_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/student_history_service.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/memory_roster_repository.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_policy.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_activity_cubit/student_activity_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_cubit/student_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';

Future<void> settle() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

class _Auth implements FirebaseAuth {
  final events = StreamController<User?>.broadcast();
  @override
  Stream<User?> authStateChanges() => events.stream;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _User implements User {
  @override
  final String uid;
  _User(this.uid);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Metadata implements SnapshotMetadata {
  @override
  final bool isFromCache;
  _Metadata(this.isFromCache);
  @override
  bool get hasPendingWrites => false;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Snapshot implements DocumentSnapshot<Map<String, dynamic>> {
  final Map<String, dynamic>? value;
  @override
  final SnapshotMetadata metadata;
  _Snapshot(this.value, {bool cached = false}) : metadata = _Metadata(cached);
  @override
  Map<String, dynamic>? data() => value;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Doc implements DocumentReference<Map<String, dynamic>> {
  final events =
      StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();
  @override
  dynamic noSuchMethod(Invocation i) =>
      i.memberName == #snapshots ? events.stream : super.noSuchMethod(i);
}

class _Collection implements CollectionReference<Map<String, dynamic>> {
  final _Doc value;
  _Collection(this.value);
  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) => value;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Firestore implements FirebaseFirestore {
  final staff = _Doc(), config = _Doc();
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _Collection(path == 'staff_access' ? staff : config);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Students implements StudentsRepo {
  final source = StreamController<List<StudentDetail>>.broadcast();
  @override
  Stream<List<StudentDetail>> watch() => source.stream;
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _History extends StudentHistoryService {
  final source = StreamController<StudentHistory>.broadcast();
  _History(super.repository);
  @override
  Stream<StudentHistory> watchMonth(String sid, BusinessDate month) =>
      source.stream;
}

void main() {
  test('shared rule only clears explicit authorization failures', () {
    expect(clearsSubscriptionData(TimeoutException('timeout')), false);
    expect(
        clearsSubscriptionData(const FormatException('bad document')), false);
    expect(
        clearsSubscriptionData(
            FirebaseException(plugin: 'firestore', code: 'unavailable')),
        false);
    expect(
        clearsSubscriptionData(
            FirebaseException(plugin: 'firestore', code: 'permission-denied')),
        true);
    expect(clearsSubscriptionData(const SubscriptionAccessDenied()), true);
  });
  group('real access repository wiring', () {
    late _Firestore db;
    late _Auth auth;
    late FirebaseRosterRepository repo;
    late StreamSubscription<RosterAccess?> sub;
    late List<RosterAccess?> values;
    late List<Object> errors;
    final staff = {
      'active': true,
      'role': 'teacher',
      'locationIds': ['a']
    };
    final config = {'status': 'enabled', 'clientWritesEnabled': true};
    setUp(() async {
      db = _Firestore();
      auth = _Auth();
      repo = FirebaseRosterRepository(db, auth);
      values = [];
      errors = [];
      sub = repo.watchAccess().listen(values.add, onError: errors.add);
      auth.events.add(_User('teacher-a'));
      await settle();
    });
    tearDown(() async {
      await sub.cancel();
      await repo.dispose();
      await auth.events.close();
      await db.staff.events.close();
      await db.config.events.close();
    });
    Future<void> authorize() async {
      db.staff.events.add(_Snapshot(staff));
      db.config.events.add(_Snapshot(config));
      await settle();
    }

    test('cached first authorization does not unlock data', () async {
      db.staff.events.add(_Snapshot(staff, cached: true));
      db.config.events.add(_Snapshot(config, cached: true));
      await settle();
      expect(values.whereType<RosterAccess>(), isEmpty);
      await authorize();
      expect(values.last!.uid, 'teacher-a');
    });
    test('transient access error retains verified identity and later recovers',
        () async {
      await authorize();
      final before = values.length;
      db.staff.events.addError(TimeoutException('offline'));
      await settle();
      expect(values.length, before);
      expect(values.last!.uid, 'teacher-a');
      expect(errors.single, isA<TimeoutException>());
      final replay = await repo.watchAccess().first;
      expect(replay!.uid, 'teacher-a');
      db.staff.events.add(_Snapshot(staff));
      await settle();
      expect(values.last!.locationIds, ['a']);
    });
    test('explicit denial and logout clear verified identity', () async {
      await authorize();
      db.staff.events.addError(
          FirebaseException(plugin: 'firestore', code: 'permission-denied'));
      await settle();
      expect(values.last, isNull);
      await authorize();
      auth.events.add(null);
      await settle();
      expect(values.last, isNull);
    });
    test('server revocation wins even while config snapshot is cached',
        () async {
      await authorize();
      db.config.events.add(_Snapshot(config, cached: true));
      await settle();
      db.staff.events.add(_Snapshot({...staff, 'active': false}));
      await settle();
      expect(values.last, isNull);
    });
    test('switching identity does not reuse cached authorization', () async {
      await authorize();
      auth.events.add(_User('teacher-b'));
      await settle();
      expect(values.last, isNull);
      db.staff.events.add(_Snapshot(staff, cached: true));
      db.config.events.add(_Snapshot(config, cached: true));
      await settle();
      expect(values.last, isNull);
    });
  });
  test('directory retains prior students on failure, clears on denial',
      () async {
    final repo = _Students();
    GetIt.I.registerSingleton<StudentsRepo>(repo);
    final cubit = StudentsCubit(StudentsState([]));
    final loading = cubit.load();
    await settle();
    repo.source
        .add([StudentDetail.empty().copyWith(id: 's', name: 'Synthetic')]);
    await loading;
    repo.source.addError(TimeoutException('offline'));
    await settle();
    expect(cubit.state.students.single.id, 's');
    expect(cubit.state.errorMessage, isNotNull);
    repo.source.addError(const SubscriptionAccessDenied());
    await settle();
    expect(cubit.state.students, isEmpty);
    await cubit.close();
    await repo.source.close();
    await GetIt.I.reset();
  });
  test('activity retains records and retry snapshot, clears on denial',
      () async {
    final source = StreamController<List<DailyRecord>>.broadcast();
    final cubit = StudentActivityCubit.watching(() => source.stream)..load();
    final row = DailyRecord('performance',
        studentId: 's',
        locationId: 'a',
        date: BusinessDate('2026-10-04'),
        values: {});
    source.add([row]);
    await settle();
    source.addError(const FormatException('malformed'));
    await settle();
    expect(cubit.state.records.single, row);
    expect(cubit.state.failed, true);
    cubit.load();
    expect(cubit.state.records.single, row);
    await settle();
    source.addError(const SubscriptionAccessDenied());
    await settle();
    expect(cubit.state.records, isEmpty);
    await cubit.close();
    await source.close();
  });
  test('history keeps same-month data but clears before a different month',
      () async {
    final repo = MemoryRosterRepository();
    final service = _History(repo);
    final month = BusinessDate('2026-10-01');
    final cubit = StudentHistoryCubit('s', service, month: month)..start();
    final data = StudentHistory(
        studentId: 's',
        name: 'Synthetic',
        from: month,
        to: BusinessDate('2026-10-31'),
        sites: [],
        enrollments: [],
        attendance: [],
        performance: [],
        statistics: const AttendanceStatistics(0, 0, 0),
        fromCache: false,
        unknownEnrollmentCoverage: false);
    service.source.add(data);
    await settle();
    service.source.addError(TimeoutException('offline'));
    await settle();
    expect(cubit.state.history, same(data));
    cubit.start();
    expect(cubit.state.history, same(data));
    await settle();
    cubit.moveMonth(-1);
    expect(cubit.state.history, isNull);
    await settle();
    await cubit.close();
    await service.source.close();
    await repo.dispose();
  });
  test('shared cache preserves last data on timeout, drops it on denial',
      () async {
    final cache = SharedStreamCache<int>();
    final source = StreamController<DataSnapshot<int>>.broadcast();
    final first = cache
        .watch('same-user', () => source.stream)
        .listen((_) {}, onError: (_) {});
    source.add(const DataSnapshot(42));
    await settle();
    source.addError(TimeoutException('offline'));
    await settle();
    expect(
        (await cache.watch('same-user', () => source.stream).first).data, 42);
    source.addError(const SubscriptionAccessDenied());
    await settle();
    final replay = <int>[];
    final second = cache
        .watch('same-user', () => source.stream)
        .listen((v) => replay.add(v.data));
    await settle();
    expect(replay, isEmpty);
    await second.cancel();
    await first.cancel();
    await cache.clear();
    await source.close();
  });
}
