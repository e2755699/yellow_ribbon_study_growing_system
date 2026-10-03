import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_commands.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_command_failure.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';

RosterMap copy(RosterMap value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);

class Store implements RosterCommandStore {
  final data = <String, RosterMap>{};
  int commits = 0, attempts = 0;
  List<String> lastWrites = [];
  final traces = <RosterMap>[];
  void Function()? conflictOnce;
  bool loseReply = false;
  @override
  Object get serverTimestamp => 'SERVER_TIME';
  @override
  Object timestamp(DateTime value) => value.toUtc().toIso8601String();
  @override
  DateTime? dateTime(Object? value) => null;
  @override
  Future<T> transaction<T>(
      Future<T> Function(RosterCommandTransaction) body) async {
    while (true) {
      attempts++;
      final tx = Tx(data);
      final result = await body(tx);
      final hook = conflictOnce;
      if (hook != null) {
        conflictOnce = null;
        hook();
        continue;
      }
      data
        ..clear()
        ..addAll(tx.data);
      lastWrites = tx.writes;
      traces.add({'reads': tx.reads, 'writes': tx.writeDetails});
      commits++;
      if (loseReply) {
        loseReply = false;
        throw const RosterCommandFailure('unavailable');
      }
      return result;
    }
  }
}

class Tx implements RosterCommandTransaction {
  final Map<String, RosterMap> data;
  final writes = <String>[];
  final reads = <String>[];
  final writeDetails = <RosterMap>[];
  Tx(Map<String, RosterMap> initial)
      : data = initial.map((k, v) => MapEntry(k, copy(v)));
  @override
  Future<RosterMap?> get(String path) async {
    if (writes.isNotEmpty) throw StateError('read after first write: $path');
    reads.add(path);
    return data[path] == null ? null : copy(data[path]!);
  }

  @override
  void set(String path, RosterMap value, {bool merge = false}) {
    writes.add(path);
    writeDetails.add({'path': path, 'data': copy(value), 'merge': merge});
    data[path] = merge ? {...?data[path], ...copy(value)} : copy(value);
  }
}

void main() {
  late Store store;
  late RosterCommands commands;
  const day = '2026-10-03';
  RosterMap request(String op,
          {String kind = 'performance', RosterMap? patch, int count = 30}) =>
      {
        'action': 'saveRecords',
        'operationId': op,
        'kind': kind,
        'locationId': 'A',
        'dateKey': day,
        'records': List.generate(
            count,
            (i) => {
                  'studentId': 's$i',
                  'enrollmentId': 'e$i',
                  'base': {},
                  'patch': patch ?? {'performanceRating': 'excellent'}
                }),
      };
  String record(int i, [String kind = 'performance']) =>
      '${kind}_records/$day.A.s$i';
  setUp(() {
    store = Store();
    commands = RosterCommands(store, clock: () => DateTime.utc(2026, 10, 3, 5));
    store.data['app_config/roster'] = {
      'status': 'enabled',
      'clientWritesEnabled': true
    };
    store.data['staff_access/t'] = {
      'active': true,
      'role': 'teacher',
      'locationIds': ['A']
    };
    store.data['staff_access/m'] = {
      'active': true,
      'role': 'manager',
      'locationIds': ['A', 'B']
    };
    store.data['class_locations/A'] = {'name': 'Site A', 'active': true};
    store.data['class_locations/B'] = {'name': 'Site B', 'active': true};
    store.data['membership_indexes/A'] = {
      'entries': {
        for (var i = 0; i < 30; i++)
          'e$i': {
            'studentId': 's$i',
            'locationId': 'A',
            'startDate': '2020-01-01',
            'endDateExclusive': '9999-12-31'
          },
      },
      'changedEnrollmentIds': []
    };
    for (var i = 0; i < 30; i++) {
      store.data['student_summaries/s$i'] = {
        'name': 'Student $i',
        'locationIds': ['A'],
        'archived': false
      };
      store.data['yellow_ribbon_counts/s$i'] = {
        'totalCount': 0,
        'usedCount': 0,
        'locationIds': ['A']
      };
    }
  });
  test(
      '30 maximum formal payloads are one transaction with reads before writes',
      () async {
    final result = await commands.execute(
        't',
        request('first', patch: {
          'performanceRating': 'excellent',
          'remarks': 'r' * 4000,
          'excellentCharacters':
              List.generate(30, (i) => '$i'.padRight(80, 'x')),
          for (final field in RosterCommands.ratingFields) field: 5,
        }));
    expect((result['records'] as Map).length, 30);
    expect(store.commits, 1);
    expect(store.lastWrites.length,
        91); // 30 records + wallets + events + receipt.
    for (var i = 0; i < 30; i++) {
      expect(store.data[record(i)]!['awardActive'], true);
      expect(store.data['yellow_ribbon_counts/s$i']!['totalCount'], 1);
      expect(store.data['ribbon_events/first.s$i']!['delta'], 1);
      expect(store.data['ribbon_events/first.s$i']!['dateKey'], day);
      expect(store.data['ribbon_events/first.s$i']!['enrollmentId'], 'e$i');
    }
  });
  test('invalid last student rejects everything before a write', () async {
    final input = request('bad');
    (input['records'] as List).last['patch'] = {'mathPerformanceRating': 6};
    final before = jsonEncode(store.data);
    await expectLater(
        commands.execute('t', input), throwsA(isA<RosterCommandFailure>()));
    expect(jsonEncode(store.data), before);
    expect(store.commits, 0);
  });
  test(
      'Chinese maximum payload fits 30; oversized 100-row receipt rejects whole transaction',
      () async {
    final patch = {
      'performanceRating': 'excellent',
      'remarks': '中' * 4000,
      'excellentCharacters': List.filled(30, '優' * 80),
      for (final f in RosterCommands.ratingFields) f: 5
    };
    await commands.execute('t', request('chinese30', patch: patch));
    final receipt = store.data['record_operations/chinese30']!;
    expect(utf8.encode(jsonEncode(receipt)).length, lessThan(900 * 1024));
    for (var i = 30; i < 100; i++) {
      store.data['membership_indexes/A']!['entries']['e$i'] = {
        'studentId': 's$i',
        'locationId': 'A',
        'startDate': '2020-01-01',
        'endDateExclusive': '9999-12-31'
      };
      store.data['student_summaries/s$i'] = {
        'name': 'Student $i',
        'locationIds': ['A']
      };
      store.data['yellow_ribbon_counts/s$i'] = {
        'totalCount': 0,
        'usedCount': 0,
        'locationIds': ['A']
      };
    }
    final before = jsonEncode(store.data), commits = store.commits;
    await expectLater(
        commands.execute('t', request('tooLarge', patch: patch, count: 100)),
        throwsA(isA<RosterCommandFailure>()
            .having((e) => e.code, 'code', 'invalid-argument')));
    expect(jsonEncode(store.data), before);
    expect(store.commits, commits);
  });
  test(
      'manager historical correction event carries original site and explicit reason',
      () async {
    store.data[record(0)] = {
      'studentId': 's0',
      'locationId': 'A',
      'dateKey': day,
      'revision': 1,
      'values': {'performanceRating': 'good'},
      'awardActive': false,
      'awardReviewRequired': false,
      'confirmedFields': [],
      'provenance': 'legacyUnverified'
    };
    final input = copy(request('correction', count: 1));
    (input['records'] as List).first['enrollmentId'] = null;
    (input['records'] as List).first['correctionReason'] = '核對歷史紙本';
    await commands.execute('m', input);
    final event = store.data['ribbon_events/correction.s0']!;
    expect(event['locationId'], 'A');
    expect(event['studentId'], 's0');
    expect(event['recordId'], '$day.A.s0');
    expect(event['dateKey'], day);
    expect(event['enrollmentId'], isNull);
    expect(event['correctionReason'], '核對歷史紙本');
  });
  test('duplicate student is rejected instead of overwriting a row', () async {
    final input = request('bad');
    (input['records'] as List).last['studentId'] = 's0';
    await expectLater(
        commands.execute('t', input), throwsA(isA<RosterCommandFailure>()));
    expect(store.commits, 0);
  });
  test(
      'lost commit response replay neither awards twice nor overwrites subsequent work',
      () async {
    final input = request('lost', count: 1);
    store.loseReply = true;
    await expectLater(
        commands.execute('t', input), throwsA(isA<RosterCommandFailure>()));
    await commands.execute(
        't', request('later', count: 1, patch: {'remarks': 'later'}));
    final old = await commands.execute('t', input);
    expect((old['records'] as Map)['s0']['revision'], 1);
    expect(store.data[record(0)]!['values']['remarks'], 'later');
    expect(store.data['yellow_ribbon_counts/s0']!['totalCount'], 1);
    expect(store.lastWrites, isEmpty);
  });
  test('same operation id different payload cannot replay', () async {
    await commands.execute('t', request('one', count: 1));
    await expectLater(
        commands.execute(
            't', request('one', count: 1, patch: {'remarks': 'other'})),
        throwsA(isA<RosterCommandFailure>()
            .having((e) => e.code, 'code', 'already-exists')));
  });
  test('transaction retry recomputes from latest fields and latest wallet',
      () async {
    await commands.execute('t', request('one', count: 1));
    store.conflictOnce = () {
      store.data[record(0)]!['values']['remarks'] = 'other teacher';
      store.data['yellow_ribbon_counts/s0']!['usedCount'] = 1;
    };
    await commands.execute(
        't', request('retry', count: 1, patch: {'performanceRating': 'good'}));
    expect(store.data[record(0)]!['values'],
        {'performanceRating': 'good', 'remarks': 'other teacher'});
    expect(store.data['yellow_ribbon_counts/s0']!['totalCount'], 0);
    expect(store.data['yellow_ribbon_counts/s0']!['usedCount'],
        1); // Existing spent-award reversal semantics.
    expect(store.attempts, 3);
  });
  test('same field uses later commit regardless of stale base', () async {
    await commands.execute(
        't', request('one', count: 1, patch: {'remarks': 'first'}));
    await commands.execute(
        't', request('two', count: 1, patch: {'remarks': 'second'}));
    expect(store.data[record(0)]!['values']['remarks'], 'second');
  });
  test(
      'legacy inactive excellent preserves unknown values and requires review on reversal',
      () async {
    store.data[record(0)] = {
      'revision': 4,
      'values': {
        'performanceRating': 'excellent',
        'homework': {'old': true},
        'mathPerformanceRating': 'import'
      },
      'awardActive': false,
      'awardReviewRequired': false,
      'provenance': 'legacyUnverified',
      'confirmedFields': []
    };
    await commands.execute(
        't', request('note', count: 1, patch: {'remarks': 'note'}));
    await commands.execute('t',
        request('reverse', count: 1, patch: {'performanceRating': 'good'}));
    expect(store.data[record(0)]!['awardReviewRequired'], true);
    expect(store.data[record(0)]!['values']['homework'], {'old': true});
    expect(store.data[record(0)]!['values']['mathPerformanceRating'], 'import');
    expect(store.data[record(0)]!['provenance'], 'partiallyConfirmed');
    expect(store.data['yellow_ribbon_counts/s0']!['totalCount'], 0);
  });
  test(
      'attendance creates held session once; cancellation is never silently reversed',
      () async {
    await commands.execute('t',
        request('attendance', kind: 'attendance', patch: {'status': 'attend'}));
    expect(
        store.lastWrites.where((p) => p.startsWith('class_sessions/')).length,
        1);
    expect(store.lastWrites.length, 32);
    await commands.execute('m', {
      'action': 'setSession',
      'operationId': 'cancel',
      'locationId': 'A',
      'dateKey': day,
      'status': 'cancelled',
      'expectedRevision': 1,
      'reason': '颱風停課'
    });
    await expectLater(
        commands.execute('t',
            request('after', kind: 'attendance', patch: {'status': 'late'})),
        throwsA(isA<RosterCommandFailure>()
            .having((e) => e.code, 'code', 'failed-precondition')));
    expect(store.data['class_sessions/$day.A']!['status'], 'cancelled');
  });
  test('attendance leave status pair clears stale reason on last commit',
      () async {
    await commands.execute(
        't',
        request('leave',
            kind: 'attendance',
            count: 1,
            patch: {'status': 'leave', 'leaveReason': 'sick'}));
    await commands.execute(
        't',
        request('attend',
            kind: 'attendance', count: 1, patch: {'status': 'attend'}));
    expect(store.data[record(0, 'attendance')]!['values'],
        {'status': 'attend', 'leaveReason': ''});
  });
  test(
      'manager enrollment, transfer, correction and archive synchronize ACL indexes',
      () async {
    await commands.execute('m', {
      'action': 'enrollStudent',
      'operationId': 'enroll',
      'studentId': 'new',
      'locationId': 'A',
      'startDate': '2026-01-01',
      'profile': {'name': 'New', 'birthday': '2015-01-01'}
    });
    await commands.execute('m', {
      'action': 'changeEnrollment',
      'operationId': 'transfer',
      'studentId': 'new',
      'mode': 'transfer',
      'locationId': 'B',
      'effectiveDate': '2026-09-01',
      'expectedRevision': 1
    });
    expect(store.data['students/new']!['locationId'], 'B');
    expect(store.data['student_summaries/new']!['locationIds'], ['A', 'B']);
    expect(store.data['yellow_ribbon_counts/new']!['locationIds'], ['A', 'B']);
    expect(
        store.data['membership_indexes/A']!['entries']['enroll']
            ['endDateExclusive'],
        '2026-09-01');
    await commands.execute('m', {
      'action': 'correctEnrollment',
      'operationId': 'correct',
      'studentId': 'new',
      'enrollmentId': 'enroll',
      'startDate': '2026-01-02',
      'endDateExclusive': '2026-09-01',
      'reason': '核對紙本日期',
      'expectedRevision': 2
    });
    expect(
        store.data['student_enrollments/enroll']!['previousPeriod']
            ['startDate'],
        '2026-01-01');
    await commands.execute('m', {
      'action': 'changeEnrollment',
      'operationId': 'archive',
      'studentId': 'new',
      'mode': 'archive',
      'effectiveDate': '2026-10-03',
      'expectedRevision': 3
    });
    expect(store.data['students/new']!['archived'], true);
    expect(store.data['yellow_ribbon_counts/new']!['locationIds'], ['A', 'B']);
  });
  test('archive or transfer on the enrollment start day is refused clearly',
      () async {
    await commands.execute('m', {
      'action': 'enrollStudent',
      'operationId': 'enroll',
      'studentId': 'today',
      'locationId': 'A',
      'startDate': '2026-10-03',
      'profile': {'name': 'Today'}
    });
    final before = jsonEncode(store.data);
    for (final change in [
      {'mode': 'archive'},
      {'mode': 'transfer', 'locationId': 'B'}
    ]) {
      await expectLater(
          commands.execute('m', {
            'action': 'changeEnrollment',
            'operationId': 'same-day-${change['mode']}',
            'studentId': 'today',
            'effectiveDate': '2026-10-03',
            'expectedRevision': 1,
            ...change
          }),
          throwsA(isA<RosterCommandFailure>()
              .having((e) => e.code, 'code', 'same-day-enrollment')
              .having((e) => e.outcomeUnknown, 'outcomeUnknown', false)
              .having((e) => e.message, 'message', contains('今天才入班'))));
    }
    expect(jsonEncode(store.data), before);
    await commands.execute('m', {
      'action': 'changeEnrollment',
      'operationId': 'next-day-archive',
      'studentId': 'today',
      'mode': 'archive',
      'effectiveDate': '2026-10-04',
      'expectedRevision': 1
    });
    expect(
        store.data['membership_indexes/A']!['entries']['enroll']
            ['endDateExclusive'],
        '2026-10-04');
  });
  test('profile patches retain unrelated fields and summary follows name',
      () async {
    store.data['students/s0'] = {
      'name': 'Before',
      'phone': '123',
      'locationId': 'A',
      'revision': 1,
      'enrollmentTimeline': [
        {
          'id': 'e0',
          'studentId': 's0',
          'locationId': 'A',
          'startDate': '2020-01-01',
          'endDateExclusive': '9999-12-31'
        }
      ],
    };
    await commands.execute('t', {
      'action': 'updateProfile',
      'operationId': 'profile',
      'studentId': 's0',
      'base': {},
      'patch': {'name': 'After'}
    });
    expect(store.data['students/s0']!['phone'], '123');
    expect(store.data['student_summaries/s0']!['name'], 'After');
  });
  test(
      'profile scope follows effective date even when stored location is stale',
      () async {
    store.data['staff_access/b'] = {
      'active': true,
      'role': 'teacher',
      'locationIds': ['B']
    };
    store.data['students/s0'] = {
      'name': 'Before',
      'locationId': 'A',
      'revision': 1,
      'enrollmentTimeline': [
        {
          'id': 'e0',
          'studentId': 's0',
          'locationId': 'A',
          'startDate': '2020-01-01',
          'endDateExclusive': '2026-10-03'
        },
        {
          'id': 'eB',
          'studentId': 's0',
          'locationId': 'B',
          'startDate': '2026-10-03',
          'endDateExclusive': '9999-12-31'
        }
      ]
    };
    final input = {
      'action': 'updateProfile',
      'operationId': 'newsite',
      'studentId': 's0',
      'base': {},
      'patch': {'name': 'After'}
    };
    await expectLater(
        commands.execute('t', input),
        throwsA(isA<RosterCommandFailure>()
            .having((e) => e.code, 'code', 'permission-denied')));
    expect((await commands.execute('b', input))['locationIds'], ['B']);
  });
  test('local Taiwan midnight clock resubscribes without database writes',
      () async {
    var now = DateTime.utc(2026, 10, 2, 15, 59, 59, 900);
    final days = <String>[];
    final subscription =
        StudentsRepo.businessDays(clock: () => now).listen(days.add);
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(days, ['2026-10-02']);
    now = DateTime.utc(2026, 10, 2, 16, 0, 0, 100);
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(days, ['2026-10-02', '2026-10-03']);
    await subscription.cancel();
  });
  test(
      'maintenance gate rejects new writes; confirmed receipt can still be recovered',
      () async {
    final input = request('saved', count: 1);
    await commands.execute('t', input);
    store.data['app_config/roster']!['clientWritesEnabled'] = false;
    await commands.execute('t', input);
    expect(store.lastWrites, isEmpty);
    await expectLater(commands.execute('t', request('new', count: 1)),
        throwsA(isA<RosterCommandFailure>()));
  });
  test(
      'legacy single-record payload receipt is read without modifying documents',
      () async {
    final input = {
      'action': 'saveRecord',
      'operationId': 'old',
      'kind': 'performance',
      'studentId': 's0',
      'locationId': 'A',
      'dateKey': day,
      'enrollmentId': 'e0',
      'base': {},
      'patch': {'remarks': 'old'}
    };
    store.data['record_operations/old'] = {
      'uid': 't',
      'hash': RosterCommands.digest(input),
      'locationIds': ['A'],
      'result': {'revision': 7}
    };
    expect(await commands.execute('t', input), {'revision': 7});
    expect(store.lastWrites, isEmpty);
  });
  test(
      'receipt hash matches old Node stable JSON including Unicode and integral double',
      () {
    final payload = {
      'action': 'saveRecord',
      'operationId': 'old',
      'kind': 'performance',
      'studentId': 's0',
      'locationId': 'A',
      'dateKey': '2026-10-03',
      'enrollmentId': 'e0',
      'base': {'mathPerformanceRating': 1.0},
      'patch': {
        'remarks': '中文\n備註',
        'excellentCharacters': ['禮貌', '🙂']
      }
    };
    expect(RosterCommands.digest(payload),
        '6488593d4d3ed4c2a5beaea6416ac4a2aa5dacd0303fc9b04c77e1faf2c1c6fd');
  });
  test('site scope and future date reject before writes', () async {
    final wrong = request('wrong')..['locationId'] = 'B';
    await expectLater(
        commands.execute('t', wrong), throwsA(isA<RosterCommandFailure>()));
    final future = request('future')..['dateKey'] = '2026-10-04';
    await expectLater(
        commands.execute('t', future), throwsA(isA<RosterCommandFailure>()));
    expect(store.commits, 0);
  });
  test(
      'read-only recovery never writes missing old operation and works during maintenance',
      () async {
    final original = request('original', count: 1);
    store.data['app_config/roster']!['status'] = 'maintenance';
    final recover = {'action': 'recoverOperation', 'original': original};
    await expectLater(
        commands.execute('t', recover),
        throwsA(isA<RosterCommandFailure>()
            .having((e) => e.code, 'code', 'failed-precondition')));
    expect(store.commits, 0);
    expect(store.data['record_operations/original'], isNull);
    store.data['record_operations/original'] = {
      'uid': 't',
      'hash': RosterCommands.digest(original),
      'locationIds': ['A'],
      'result': {'revision': 9}
    };
    expect(await commands.execute('t', recover), {'revision': 9});
    expect(store.lastWrites, isEmpty);
  });
  test('export production planner traces for real Rules client replay',
      () async {
    // Emulator request.time is real. Regenerate traces on the replay day.
    commands = RosterCommands(store);
    final traceDay = commands.today;
    store.data.removeWhere((k, v) =>
        k.startsWith('student_summaries/') ||
        k.startsWith('yellow_ribbon_counts/'));
    store.data['membership_indexes/A'] = {
      'entries': {},
      'changedEnrollmentIds': []
    };
    store.data['membership_indexes/B'] = {
      'entries': {},
      'changedEnrollmentIds': []
    };
    final fixtures = store.data.map((k, v) => MapEntry(k, copy(v)));
    Future<void> run(String uid, RosterMap payload) async {
      if (payload.containsKey('dateKey')) {
        payload = {...payload, 'dateKey': traceDay};
      }
      await commands.execute(uid, payload);
      store.traces.last.addAll({'uid': uid, 'input': payload});
    }

    for (var i = 0; i < 30; i++) {
      await run('m', {
        'action': 'enrollStudent',
        'operationId': 'e$i',
        'studentId': 's$i',
        'locationId': 'A',
        'startDate': '2020-01-01',
        'profile': {'name': 'Student $i'}
      });
    }
    await run(
        't',
        request('trace_first', patch: {
          'performanceRating': 'excellent',
          'remarks': 'r' * 4000,
          'excellentCharacters':
              List.generate(30, (i) => '$i'.padRight(80, 'x')),
          for (final f in RosterCommands.ratingFields) f: 5
        }));
    await run('t', request('trace_notes', patch: {'remarks': 'second'}));
    await run('t', {
      'action': 'redeemRibbon',
      'operationId': 'trace_redeem',
      'studentId': 's1',
      'amount': 1
    });
    await run(
        't', request('trace_reverse', patch: {'performanceRating': 'good'}));
    await run(
        't',
        request('trace_attendance',
            kind: 'attendance', patch: {'status': 'attend'}));
    await run('m', {
      'action': 'changeEnrollment',
      'operationId': 'trace_transfer',
      'studentId': 's0',
      'mode': 'transfer',
      'locationId': 'B',
      'effectiveDate': '2026-10-02',
      'expectedRevision': 1
    });
    await run('m', {
      'action': 'correctEnrollment',
      'operationId': 'trace_correct',
      'studentId': 's0',
      'enrollmentId': 'e0',
      'startDate': '2020-01-02',
      'endDateExclusive': '2026-10-02',
      'reason': '確認紙本資料',
      'expectedRevision': 2
    });
    await run('t', {
      'action': 'updateProfile',
      'operationId': 'trace_profile',
      'studentId': 's2',
      'base': {},
      'patch': {'name': 'Updated Student'}
    });
    await run('m', {
      'action': 'saveRecord',
      'operationId': 'trace_history_correction',
      'kind': 'performance',
      'locationId': 'A',
      'dateKey': day,
      'studentId': 's0',
      'enrollmentId': null,
      'base': {},
      'patch': {'performanceRating': 'excellent'},
      'correctionReason': '核對歷史紙本'
    });
    await run('m', {
      'action': 'setSession',
      'operationId': 'trace_cancel',
      'locationId': 'A',
      'dateKey': day,
      'status': 'cancelled',
      'expectedRevision': 1,
      'reason': '颱風取消課次'
    });
    if (Platform.environment['ROSTER_EXPORT_TRACE'] == '1') {
      File('firebase/tests/roster-planner-traces.json')
          .writeAsStringSync('${const JsonEncoder.withIndent('  ').convert({
            'dateKey': traceDay,
            'timestampMarker': 'SERVER_TIME',
            'fixtures': fixtures,
            'transactions': store.traces
          })}\n');
    }
    expect(store.traces.length, 40);
  });
  test(
      'redemption retains balance bound, idempotency and archived-student behavior',
      () async {
    store.data['students/s0'] = {
      'locationId': 'A',
      'enrollmentTimeline': [
        {
          'id': 'e0',
          'studentId': 's0',
          'locationId': 'A',
          'startDate': '2020-01-01',
          'endDateExclusive': '2025-01-01'
        }
      ]
    };
    store.data['yellow_ribbon_counts/s0']!['totalCount'] = 2;
    final redeem = {
      'action': 'redeemRibbon',
      'operationId': 'redeem',
      'studentId': 's0',
      'amount': 2
    };
    await commands.execute('t', redeem);
    await commands.execute('t', redeem);
    expect(store.data['yellow_ribbon_counts/s0']!['usedCount'], 2);
    expect(store.data['yellow_ribbon_counts/s0']!['dateKey'], day);
    expect(store.data['ribbon_events/redeem.s0']!['dateKey'], day);
    await expectLater(
        commands
            .execute('t', {...redeem, 'operationId': 'overspend', 'amount': 1}),
        throwsA(isA<RosterCommandFailure>()));
  });
}
