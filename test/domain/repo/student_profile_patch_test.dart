import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_repository.dart';

class _Commands implements RosterRepository {
  Map<String, dynamic>? payload;
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
