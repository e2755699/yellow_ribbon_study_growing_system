import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/daily_roster_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/daily_roster_service.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/draft_store.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/memory_roster_repository.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_models.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_repository.dart';

class FailingDraftStore extends MemoryDraftStore {
  @override
  Future<void> write(
      String uid, String scope, Map<String, dynamic>? data) async {
    throw StateError('device storage unavailable');
  }
}

class AccessErrorRepository extends MemoryRosterRepository {
  AccessErrorRepository(
      {super.access, super.sites, super.students, super.enrollments});
  final accessEvents = StreamController<RosterAccess?>.broadcast();
  @override
  Stream<RosterAccess?> watchAccess() => accessEvents.stream;
  @override
  Future<void> dispose() async {
    await accessEvents.close();
    await super.dispose();
  }
}

void main() {
  final date = BusinessDate('2026-10-02');
  late MemoryRosterRepository repo;
  late MemoryDraftStore store;
  late DailyRosterCubit cubit;
  Enrollment enrollment(String sid) => Enrollment('e_' + sid,
      studentId: sid,
      locationId: 'l',
      startDate: date,
      endDateExclusive: BusinessDate('9999-12-31'));
  Future<void> settle() async {
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  setUp(() async {
    repo = MemoryRosterRepository(
        access: RosterAccess('user', 'manager', ['l']),
        sites: [const ClassSite('l', '合成點')],
        students: [const StudentSummary('a', '合成甲')],
        enrollments: [enrollment('a')]);
    store = MemoryDraftStore();
    cubit = DailyRosterCubit(
        kind: 'attendance',
        service: DailyRosterService(repo),
        draftStore: store,
        date: date)
      ..start();
    await settle();
  });
  tearDown(() async {
    await cubit.close();
    await repo.dispose();
  });
  test(
      'access stream errors hide private drafts and ignore pending acknowledgements',
      () async {
    await cubit.close();
    await repo.dispose();
    final failing = AccessErrorRepository(
        access: RosterAccess('user', 'manager', ['l']),
        sites: [const ClassSite('l', '合成點')],
        students: [const StudentSummary('a', '合成甲')],
        enrollments: [enrollment('a')]);
    repo = failing;
    cubit = DailyRosterCubit(
        kind: 'attendance',
        service: DailyRosterService(repo),
        draftStore: store,
        date: date,
        initialLocationId: 'l')
      ..start();
    failing.accessEvents.add(failing.access);
    await settle();
    cubit.edit('a', 'status', 'attend');
    failing.saveGate = Completer<void>();
    final saving = cubit.saveBeforeExit();
    await settle();
    failing.accessEvents.addError(StateError('permission denied'));
    await settle();
    expect(cubit.state.access, isNull);
    expect(cubit.state.roster, isNull);
    expect(cubit.state.drafts, isEmpty);
    expect(cubit.state.saving, isFalse);
    failing.saveGate!.complete();
    await saving;
    await settle();
    expect(cubit.state.roster, isNull);
    expect(cubit.state.drafts, isEmpty);
    expect(await store.read('user', 'attendance|2026-10-02|l'), isNotNull);
  });
  test('realtime new student joins without clearing another student draft',
      () async {
    cubit.edit('a', 'status', 'attend');
    repo.students = [...repo.students, const StudentSummary('b', '合成乙')];
    repo.enrollments = [...repo.enrollments, enrollment('b')];
    repo.notify();
    await settle();
    expect(cubit.state.roster!.members.length, 2);
    expect(cubit.values('a')['status'], 'attend');
    expect(cubit.values('b')['status'], isNull);
    cubit.search('合成乙');
    expect(cubit.visibleMembers.length, 1);
    expect(cubit.state.roster!.members.length, 2);
  });
  test('unmodified page writes nothing, including no new operation', () async {
    expect(await cubit.saveBeforeExit(), isTrue);
    expect(repo.commands, isEmpty);
  });
  test('one row failure preserves only failed draft; retry uses same operation',
      () async {
    repo.students = [...repo.students, const StudentSummary('b', '合成乙')];
    repo.enrollments = [...repo.enrollments, enrollment('b')];
    repo.notify();
    await settle();
    cubit.edit('a', 'status', 'attend');
    cubit.edit('b', 'status', 'leave');
    repo.failStudents.add('b');
    expect(await cubit.saveBeforeExit(), isFalse);
    expect(cubit.state.drafts.keys, ['b']);
    final op = repo.commands.last['operationId'];
    repo.failStudents.clear();
    expect(await cubit.saveBeforeExit(), isTrue);
    expect(repo.commands.last['operationId'], op);
    expect(repo.commands.where((p) => p['studentId'] == 'a').length, 1);
  });
  test('ack preserves new input typed while saving', () async {
    cubit.edit('a', 'status', 'attend');
    repo.saveGate = Completer<void>();
    final saving = cubit.saveBeforeExit();
    await settle();
    cubit.edit('a', 'status', 'late');
    repo.saveGate!.complete();
    expect(await saving, isFalse);
    expect(cubit.values('a')['status'], 'late');
    expect(cubit.state.drafts['a']!.base['status'], 'attend');
  });
  test('cancel restores remote data; restart restores only the same user draft',
      () async {
    cubit.edit('a', 'status', 'leave');
    await cubit.persist();
    expect(await store.read('other', 'attendance|2026-10-02|l'), isNull);
    await cubit.close();
    cubit = DailyRosterCubit(
        kind: 'attendance',
        service: DailyRosterService(repo),
        draftStore: store,
        date: date)
      ..start();
    await settle();
    expect(cubit.values('a')['status'], 'leave');
    await cubit.discard('a');
    expect(cubit.values('a')['status'], isNull);
  });
  test('membership removal prevents saving the old draft', () async {
    cubit.edit('a', 'status', 'attend');
    repo.enrollments = [];
    repo.notify();
    await settle();
    expect(await cubit.saveBeforeExit(), isFalse);
    expect(repo.commands, isEmpty);
    expect(cubit.state.rowErrors['a'], isNotNull);
  });
  test('draft deeply detaches nested edits from caller objects', () {
    final tags = ['help'];
    final draft = RecordDraft({}, {'excellentCharacters': tags});
    tags.add('changed');
    expect(draft.patch['excellentCharacters'], ['help']);
    expect(() => (draft.patch['excellentCharacters'] as List).add('changed'),
        throwsUnsupportedError);
  });
  test('failed local persistence blocks sending an operation and leaving page',
      () async {
    await cubit.close();
    cubit = DailyRosterCubit(
        kind: 'attendance',
        service: DailyRosterService(repo),
        draftStore: FailingDraftStore(),
        date: date)
      ..start();
    await settle();
    cubit.edit('a', 'status', 'attend');
    expect(await cubit.saveBeforeExit(), isFalse);
    expect(repo.commands, isEmpty);
    expect(cubit.state.saving, isFalse);
    expect(cubit.state.drafts, isNotEmpty);
    expect(cubit.state.error, contains('本機'));
  });
  test('search never changes total or marked counts', () {
    cubit.edit('a', 'status', 'attend');
    cubit.search('no match');
    expect(cubit.visibleMembers, isEmpty);
    expect(cubit.counts.total, 1);
    expect(cubit.counts.marked, 1);
  });
  test('session cancellation retains records and prevents edits', () async {
    expect(await cubit.setSession(SessionStatus.held), isTrue);
    cubit.edit('a', 'status', 'attend');
    await cubit.saveBeforeExit();
    expect(await cubit.setSession(SessionStatus.cancelled, reason: '颱風停課日'),
        isTrue);
    cubit.edit('a', 'status', 'absent');
    expect(cubit.values('a')['status'], 'attend');
    expect(cubit.hasUnsavedChanges, isFalse);
    expect(cubit.canEdit('a'), isFalse);
  });
  test(
      'revoking access clears visible drafts, retains private recovery and ignores late ack',
      () async {
    cubit.edit('a', 'status', 'attend');
    repo.saveGate = Completer<void>();
    final saving = cubit.saveBeforeExit();
    await settle();
    repo.access = null;
    repo.notify();
    await settle();
    expect(cubit.state.roster, isNull);
    expect(cubit.state.drafts, isEmpty);
    expect(cubit.values('a'), isEmpty);
    repo.saveGate!.complete();
    expect(await saving, isFalse);
    expect(await store.read('user', 'attendance|2026-10-02|l'), isNotNull);
    repo.access = RosterAccess('other', 'teacher', ['l']);
    repo.notify();
    await settle();
    expect(cubit.state.drafts, isEmpty);
  });
}
