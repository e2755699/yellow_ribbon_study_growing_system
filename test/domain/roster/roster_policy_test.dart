import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_models.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_policy.dart';

void main() {
  final enrollment = Enrollment('e',
      studentId: 's',
      locationId: 'l',
      startDate: BusinessDate('2026-10-02'),
      endDateExclusive: BusinessDate('2026-10-05'));
  test('enrollment is start-inclusive and end-exclusive', () {
    expect(enrollment.includes(BusinessDate('2026-10-01')), isFalse);
    expect(enrollment.includes(BusinessDate('2026-10-02')), isTrue);
    expect(enrollment.includes(BusinessDate('2026-10-04')), isTrue);
    expect(enrollment.includes(BusinessDate('2026-10-05')), isFalse);
  });
  test('Taiwan business day is independent of UTC midnight', () {
    expect(
        BusinessDate.today(DateTime.utc(2026, 10, 1, 16)).value, '2026-10-02');
    expect(() => BusinessDate('2026-02-30'), throwsFormatException);
  });
  test('new student joins both pages, missing record remains unmarked', () {
    final rows = RosterPolicy.members(BusinessDate('2026-10-02'), 'l',
        [enrollment], [const StudentSummary('s', '合成學生')]);
    expect(rows.single.student.id, 's');
    expect(
        RosterPolicy.members(BusinessDate('2026-10-01'), 'l', [enrollment],
            [const StudentSummary('s', '合成學生')]),
        isEmpty);
  });
  test('overlapping memberships are an error, not duplicate students', () {
    expect(
        () => RosterPolicy.members(BusinessDate('2026-10-02'), 'l',
            [enrollment, enrollment], [const StudentSummary('s', '合成學生')]),
        throwsStateError);
  });
  test('only confirmed held sessions during enrollment enter denominator', () {
    final sessions = [
      ClassSession('l', BusinessDate('2026-10-01'), SessionStatus.held),
      ClassSession('l', BusinessDate('2026-10-02'), SessionStatus.held),
      ClassSession('l', BusinessDate('2026-10-03'), SessionStatus.held),
      ClassSession('l', BusinessDate('2026-10-04'), SessionStatus.cancelled),
      ClassSession('l', BusinessDate('2026-10-05'), SessionStatus.held),
    ];
    final stats = AttendanceStatistics.calculate(
        studentId: 's',
        enrollments: [enrollment],
        sessions: sessions,
        records: [
          DailyRecord('attendance',
              studentId: 's',
              locationId: 'l',
              date: BusinessDate('2026-10-02'),
              values: {'status': 'attend'}),
        ]);
    expect(stats.expected, 2);
    expect(stats.confirmed, 1);
    expect(stats.present, 1);
    expect(stats.rate, 1);
    expect(stats.isFinal, isFalse);
  });
  test('legacy unverified values do not become confirmed attendance', () {
    final stats = AttendanceStatistics.calculate(studentId: 's', enrollments: [
      enrollment
    ], sessions: [
      ClassSession('l', BusinessDate('2026-10-02'), SessionStatus.held),
    ], records: [
      DailyRecord('attendance',
          studentId: 's',
          locationId: 'l',
          date: BusinessDate('2026-10-02'),
          values: {'status': 'absent'},
          provenance: 'legacyUnverified'),
    ]);
    expect(stats.confirmed, 0);
    expect(stats.rate, isNull);
    expect(stats.isFinal, isFalse);
  });
  test('DTOs freeze nested collections and retain record identity', () {
    final tags = ['helper'];
    final record = DailyRecord('performance',
        studentId: 's',
        locationId: 'l',
        date: BusinessDate('2026-10-02'),
        values: {'tags': tags});
    tags.add('other');
    expect(record.values['tags'], ['helper']);
    expect(
        () => (record.values['tags'] as List).add('x'), throwsUnsupportedError);
    expect(record.id, '2026-10-02.l.s');
  });
}
