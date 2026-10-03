import 'dart:async';
import 'package:yellow_ribbon_study_growing_system/domain/utils/subscription_failure.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/daily_roster_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/daily_roster_service.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/draft_store.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/memory_roster_repository.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_models.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_repository.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_command_failure.dart';

class CommandFailureRepository extends MemoryRosterRepository {
  CommandFailureRepository(
      {super.access, super.sites, super.students, super.enrollments});
  String? failureCode;
  bool loseNextResponse = false;
  bool truncateNextResponse = false;
  @override
  Future<Map<String, dynamic>> command(Map<String, dynamic> payload) async {
    if (failureCode != null) throw RosterCommandFailure(failureCode!);
    final result = await super.command(payload);
    if (truncateNextResponse) {
      truncateNextResponse = false;
      return {'records': {}};
    }
    if (loseNextResponse) {
      loseNextResponse = false;
      throw const RosterCommandFailure('unavailable');
    }
    return result;
  }
}

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
    repo = CommandFailureRepository(
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
      'explicit access denial hides drafts and ignores pending acknowledgements',
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
    failing.accessEvents.addError(const SubscriptionAccessDenied());
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
  test('transient access failure retains roster and unsaved edits for saving',
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
    failing.accessEvents.addError(TimeoutException('temporary outage'));
    await settle();
    expect(cubit.state.access, isNotNull);
    expect(cubit.state.roster!.members.single.student.id, 'a');
    expect(cubit.values('a')['status'], 'attend');
    expect(cubit.state.drafts.keys, ['a']);
    expect(cubit.state.error, isNotNull);
    expect(repo.commands, isEmpty);
    failing.accessEvents.add(failing.access);
    await settle();
    expect(cubit.values('a')['status'], 'attend');
    expect(await cubit.saveBeforeExit(), isTrue);
    expect(repo.records.single.values['status'], 'attend');
    expect(repo.commands, hasLength(1));
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
  test('one rejected row rolls back the entire batch and preserves all drafts',
      () async {
    repo.students = [...repo.students, const StudentSummary('b', '合成乙')];
    repo.enrollments = [...repo.enrollments, enrollment('b')];
    repo.notify();
    await settle();
    cubit.edit('a', 'status', 'attend');
    cubit.edit('b', 'status', 'leave');
    repo.failStudents.add('b');
    expect(await cubit.saveBeforeExit(), isFalse);
    expect(cubit.state.drafts.keys, ['a', 'b']);
    expect(repo.commands, hasLength(1));
    expect(repo.commands.single['action'], 'saveRecords');
    expect(repo.records, isEmpty);
    expect(repo.receipts, isEmpty);
    expect(repo.sessions, isEmpty);
    expect(cubit.state.saveFeedback!.incomplete, isTrue);
    expect(cubit.state.saveFeedback!.message, contains('整批儲存失敗'));
    expect(cubit.state.saveFeedback!.message, contains('合成乙'));
    expect(cubit.state.drafts.values.every((d) => d.pending == null), isTrue);
    repo.notify();
    await settle();
    expect(cubit.state.saveFeedback!.message, contains('合成乙'));
    final op = repo.commands.last['operationId'];
    repo.failStudents.clear();
    expect(await cubit.saveBeforeExit(), isTrue);
    expect(repo.commands.last['operationId'], isNot(op));
    expect(repo.records, hasLength(2));
    expect(repo.records.every((r) => r.revision == 1), isTrue);
    expect(repo.sessions.single.status, SessionStatus.held);
    expect(cubit.state.saveFeedback!.incomplete, isFalse);
  });
  test('lost response keeps receipt identity and cannot be discarded as unsent',
      () async {
    (repo as CommandFailureRepository).loseNextResponse = true;
    cubit.edit('a', 'status', 'attend');
    expect(await cubit.saveBeforeExit(), isFalse);
    final operation = cubit.state.drafts['a']!.pending!['operationId'];
    expect(repo.records.single.revision, 1);
    expect(cubit.state.rowErrors['a'], contains('尚未確認'));
    await cubit.discard('a');
    await cubit.keepLocal('a');
    expect(cubit.state.drafts['a']!.pending!['operationId'], operation);
    expect(await cubit.saveBeforeExit(), isTrue);
    expect(repo.commands.last['operationId'], operation);
    expect(repo.records.single.revision, 1);
    expect(cubit.state.saveFeedback!.message, contains('儲存成功'));
  });
  for (final code in [
    'permission-denied',
    'unauthenticated',
    'invalid-argument',
    'failed-precondition',
    'aborted'
  ]) {
    test(
        '$code reports a rejected write and blocks leaving with the draft intact',
        () async {
      (repo as CommandFailureRepository).failureCode = code;
      cubit.edit('a', 'status', 'attend');
      expect(await cubit.open(BusinessDate('2026-10-01'), 'l'), isFalse);
      expect(cubit.state.date, date);
      expect(cubit.state.rowErrors['a'], startsWith('儲存失敗'));
      expect(cubit.state.commandFailures['a']!.conflict, code == 'aborted');
      expect(cubit.state.drafts['a']!.pending, isNull);
      expect(cubit.state.drafts['a']!.patch['status'], 'attend');
      expect(cubit.state.saveFeedback!.message, contains('合成甲'));
      expect(repo.records, isEmpty);
    });
  }
  test(
      'permission rejection during receipt recovery does not imply the first write failed',
      () async {
    final failing = repo as CommandFailureRepository;
    failing.loseNextResponse = true;
    cubit.edit('a', 'status', 'attend');
    expect(await cubit.saveBeforeExit(), isFalse);
    final operation = cubit.state.drafts['a']!.pending!['operationId'];
    failing.failureCode = 'permission-denied';
    expect(await cubit.saveBeforeExit(), isFalse);
    expect(cubit.state.rowErrors['a'], contains('原儲存結果尚未確認'));
    expect(cubit.state.drafts['a']!.pending!['operationId'], operation);
    expect(repo.records.single.revision, 1);
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
  test('maintenance allows pending receipt recovery but blocks new writes',
      () async {
    cubit.edit('a', 'status', 'attend');
    (repo as CommandFailureRepository).loseNextResponse = true;
    expect(await cubit.saveBeforeExit(), isFalse);
    repo.access = RosterAccess('user', 'manager', ['l'], enabled: false);
    repo.notify();
    await settle();
    expect(cubit.canEdit('a'), isFalse);
    expect(cubit.canSave, isTrue);
    expect(await cubit.saveBeforeExit(), isTrue);
    expect(repo.records.single.revision, 1);
    expect(cubit.state.drafts, isEmpty);
    expect(cubit.canSave, isFalse);
    cubit.edit('a', 'status', 'late');
    expect(cubit.state.drafts, isEmpty);
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
  Future<void> addStudents(int count) async {
    repo.students = [
      for (var i = 0; i < count; i++) StudentSummary('s$i', '合成學生$i'),
    ];
    repo.enrollments = [
      for (var i = 0; i < count; i++) enrollment('s$i'),
    ];
    repo.notify();
    await settle();
  }

  test('thirty edits are one command; double save waits for the same batch',
      () async {
    await addStudents(30);
    for (var i = 0; i < 30; i++) {
      cubit.edit('s$i', 'status', 'attend');
    }
    repo.saveGate = Completer<void>();
    final first = cubit.saveBeforeExit();
    final second = cubit.saveBeforeExit();
    await settle();
    expect(repo.commands, hasLength(1));
    expect(repo.commands.single['records'], hasLength(30));
    expect(
        cubit.state.drafts.values
            .where((d) => d.pending?.containsKey('records') == true),
        hasLength(1));
    repo.saveGate!.complete();
    expect(await first, isTrue);
    expect(await second, isTrue);
    expect(repo.records, hasLength(30));
    expect(cubit.state.drafts, isEmpty);
  });

  test('lost whole-batch response survives restart and applies each row once',
      () async {
    await addStudents(3);
    for (var i = 0; i < 3; i++) cubit.edit('s$i', 'status', 'attend');
    (repo as CommandFailureRepository).loseNextResponse = true;
    expect(await cubit.saveBeforeExit(), isFalse);
    final original = repo.commands.single;
    expect(cubit.state.drafts, hasLength(3));
    await cubit.discard('s1');
    expect(cubit.state.drafts, hasLength(3));
    await cubit.close();
    cubit = DailyRosterCubit(
        kind: 'attendance',
        service: DailyRosterService(repo),
        draftStore: store,
        date: date)
      ..start();
    await settle();
    expect(await cubit.saveBeforeExit(), isTrue);
    expect(repo.commands.last, original);
    expect(repo.records.every((r) => r.revision == 1), isTrue);
    expect(cubit.state.drafts, isEmpty);
  });

  test('incomplete acknowledgement does not clear any row and retries receipt',
      () async {
    await addStudents(2);
    cubit.edit('s0', 'status', 'attend');
    cubit.edit('s1', 'status', 'late');
    (repo as CommandFailureRepository).truncateNextResponse = true;
    expect(await cubit.saveBeforeExit(), isFalse);
    expect(cubit.state.drafts, hasLength(2));
    expect(cubit.state.saveFeedback!.message, contains('結果尚未確認'));
    expect(await cubit.saveBeforeExit(), isTrue);
    expect(repo.records.every((r) => r.revision == 1), isTrue);
  });

  test('a membership change blocks all fresh rows before any write', () async {
    await addStudents(2);
    cubit.edit('s0', 'status', 'attend');
    cubit.edit('s1', 'status', 'attend');
    repo.enrollments = [enrollment('s0')];
    repo.notify();
    await settle();
    expect(await cubit.saveBeforeExit(), isFalse);
    expect(repo.commands, isEmpty);
    expect(repo.records, isEmpty);
    expect(cubit.state.drafts, hasLength(2));
  });

  test('new student input during save remains a separate unsent draft',
      () async {
    await addStudents(2);
    cubit.edit('s0', 'status', 'attend');
    repo.saveGate = Completer<void>();
    final saving = cubit.saveBeforeExit();
    await settle();
    cubit.edit('s1', 'status', 'late');
    repo.saveGate!.complete();
    expect(await saving, isFalse);
    expect(repo.records.single.studentId, 's0');
    expect(cubit.state.drafts.keys, ['s1']);
    expect(cubit.state.drafts['s1']!.pending, isNull);
    expect(cubit.state.saveFeedback!.message, contains('整批儲存成功'));
    expect(cubit.state.saveFeedback!.message, contains('新修改'));
    expect(await cubit.saveBeforeExit(), isTrue);
    expect(repo.records, hasLength(2));
  });

  test('recovered old receipt cannot overwrite a newer remote revision',
      () async {
    cubit.edit('a', 'status', 'attend');
    (repo as CommandFailureRepository).loseNextResponse = true;
    expect(await cubit.saveBeforeExit(), isFalse);
    await repo.command({
      'action': 'saveRecords',
      'operationId': 'other-teacher',
      'kind': 'attendance',
      'locationId': 'l',
      'dateKey': date.value,
      'records': [
        {
          'studentId': 'a',
          'enrollmentId': 'e_a',
          'base': {},
          'patch': {'status': 'late'}
        }
      ],
    });
    await settle();
    expect(await cubit.saveBeforeExit(), isTrue);
    expect(cubit.values('a')['status'], 'late');
    expect(cubit.state.roster!.attendance['a']!.revision, 2);
  });

  test('two devices merge untouched fields and last commit wins the same field',
      () async {
    final other = DailyRosterCubit(
        kind: 'attendance',
        service: DailyRosterService(repo),
        draftStore: MemoryDraftStore(),
        date: date)
      ..start();
    try {
      await settle();
      cubit.edit('a', 'status', 'leave');
      other.edit('a', 'leaveReason', '就醫');
      expect(await cubit.saveBeforeExit(), isTrue);
      await settle();
      expect(await other.saveBeforeExit(), isTrue);
      await settle();
      expect(cubit.values('a'), containsPair('status', 'leave'));
      expect(cubit.values('a'), containsPair('leaveReason', '就醫'));
      cubit.edit('a', 'status', 'attend');
      other.edit('a', 'status', 'late');
      expect(await cubit.saveBeforeExit(), isTrue);
      expect(await other.saveBeforeExit(), isTrue);
      await settle();
      expect(cubit.values('a')['status'], 'late');
      expect(other.values('a')['status'], 'late');
    } finally {
      await other.close();
    }
  });

  test('legacy pending receipt is recovered read-only before a new batch',
      () async {
    final original = <String, dynamic>{
      'action': 'saveRecord',
      'operationId': 'legacy',
      'kind': 'attendance',
      'locationId': 'l',
      'dateKey': date.value,
      'studentId': 'a',
      'enrollmentId': 'e_a',
      'base': {},
      'patch': {'status': 'attend'},
    };
    await repo.command(original);
    await settle();
    await cubit.close();
    await store.write('user', 'attendance|2026-10-02|l', {
      'a': RecordDraft({}, {'status': 'attend'},
              pending: original, enrollmentId: 'e_a')
          .toJson(),
    });
    cubit = DailyRosterCubit(
        kind: 'attendance',
        service: DailyRosterService(repo),
        draftStore: store,
        date: date)
      ..start();
    await settle();
    expect(await cubit.saveBeforeExit(), isTrue);
    expect(repo.commands.last['action'], 'recoverOperation');
    expect(repo.records.single.revision, 1);
    expect(cubit.state.drafts, isEmpty);
  });

  test('missing legacy receipt never becomes a new write', () async {
    await cubit.close();
    await store.write('user', 'attendance|2026-10-02|l', {
      'a': RecordDraft({}, {'status': 'attend'},
          enrollmentId: 'e_a',
          pending: {
            'action': 'saveRecord',
            'operationId': 'missing',
            'kind': 'attendance',
            'locationId': 'l',
            'dateKey': date.value,
            'studentId': 'a',
            'enrollmentId': 'e_a',
            'base': {},
            'patch': {'status': 'attend'},
          }).toJson(),
    });
    cubit = DailyRosterCubit(
        kind: 'attendance',
        service: DailyRosterService(repo),
        draftStore: store,
        date: date)
      ..start();
    await settle();
    expect(await cubit.saveBeforeExit(), isFalse);
    expect(repo.commands.single['action'], 'recoverOperation');
    expect(repo.records, isEmpty);
    expect(cubit.state.drafts['a']!.pending!['operationId'], 'missing');
    expect(cubit.state.commandFailures['a']!.outcomeUnknown, isTrue);
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
