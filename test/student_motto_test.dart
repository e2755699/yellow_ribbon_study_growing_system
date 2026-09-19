import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';

void main() {
  Map<String, dynamic> jsonFixture() {
    final student = StudentDetail.empty();
    return student.toJson()..['birthday'] = student.birthday.toIso8601String();
  }

  test('old, null, and blank mottos display the original encouragement', () {
    final json = jsonFixture()..remove('motto');
    expect(
        StudentDetail.fromJson(json).displayMotto, StudentDetail.defaultMotto);
    for (final value in [null, '', ' \n  ']) {
      json['motto'] = value;
      expect(StudentDetail.fromJson(json).displayMotto,
          StudentDetail.defaultMotto);
    }
  });

  test('custom motto survives serialization and unrelated profile updates', () {
    final json = jsonFixture()..['motto'] = '  慢慢來，比較快。  ';
    final student = StudentDetail.fromJson(json);
    final updated = student.copyWith(name: '測試學生', avatar: 'new-avatar.png');
    expect(updated.displayMotto, '慢慢來，比較快。');
    expect(updated.toJson()['motto'], '慢慢來，比較快。');
    final reloaded = StudentDetail.fromJson(
        updated.toJson()..['birthday'] = updated.birthday.toIso8601String());
    expect(reloaded.displayMotto, '慢慢來，比較快。');
    expect(
        reloaded.copyWith(motto: '').displayMotto, StudentDetail.defaultMotto);
    expect(reloaded.copyWith(motto: '').toJson()['motto'], '');
  });
}
