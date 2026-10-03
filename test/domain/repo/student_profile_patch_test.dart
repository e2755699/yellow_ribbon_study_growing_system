import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/roster_repository.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/roster/roster_command_failure.dart';

class _Commands implements RosterRepository {
  Map<String, dynamic>? payload;
  @override
  Stream<RosterAccess?> watchAccess() => Stream.value(null);
  @override
  Future<Map<String, dynamic>> command(Map<String, dynamic> value) async {
    payload = value;
    return {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoFirestore implements FirebaseFirestore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('missing access has a distinct profile error', () async {
    final repo = StudentsRepo(roster: _Commands(), firestore: _NoFirestore());
    await expectLater(repo.watchById('synthetic'),
        emitsError(isA<StudentProfileAccessDenied>()));
  });
  test('invalid creation fails definitively before issuing a command',
      () async {
    final commands = _Commands();
    final repo = StudentsRepo(roster: commands, firestore: _NoFirestore());
    await expectLater(
        repo.create(StudentDetail.empty()),
        throwsA(isA<RosterCommandFailure>()
            .having((e) => e.outcomeUnknown, 'unknown', false)));
    expect(commands.payload, isNull);
  });
  test(
      'missing legacy fields use absent server base while form defaults stay visual',
      () async {
    final commands = _Commands(),
        repo = StudentsRepo(roster: _Commands(), firestore: _NoFirestore());
    final actual = StudentsRepo(roster: commands, firestore: repo.firestore);
    final old = StudentDetail.fromJson(
        {'id': 's', 'name': '合成學生', 'classLocation': '合成點', 'locationId': 'a'});
    final attached = old.copyWith(avatar: 'synthetic.jpg');
    await actual.update('s', attached.copyWith(phone: 'synthetic-phone'),
        expected: attached);
    expect(commands.payload!['patch'], {'phone': 'synthetic-phone'});
    expect((commands.payload!['base'] as Map)['phone'], isNull);
    expect((commands.payload!['base'] as Map)['name'], '合成學生');
    expect(
        (commands.payload!['patch'] as Map).containsKey('birthday'), isFalse);
  });
  test('unchanged form sends no command and raw metadata never serializes',
      () async {
    final commands = _Commands(),
        repo = StudentsRepo(roster: _Commands(), firestore: _NoFirestore());
    final actual = StudentsRepo(roster: commands, firestore: repo.firestore);
    final old = StudentDetail.fromJson({'id': 's', 'name': '合成學生'});
    await actual.update('s', old, expected: old);
    expect(commands.payload, isNull);
    expect(old.toJson().containsKey('persistedProfile'), isFalse);
  });
}
