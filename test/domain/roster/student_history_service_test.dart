import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/roster/roster_models.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/roster_repository.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/memory_roster_repository.dart';
import 'package:yellow_ribbon_study_growing_system/domain/service/student_history_service.dart';

void main() {
  late MemoryRosterRepository repo;
  final oct = BusinessDate('2026-10-02');
  DailyRecord attendance(String date, String site, String status) =>
      DailyRecord('attendance',
          studentId: 's',
          locationId: site,
          date: BusinessDate(date),
          values: {'status': status});
  setUp(() => repo = MemoryRosterRepository(
          access: RosterAccess('user', 'manager', ['a', 'b']),
          sites: const [
            ClassSite('a', '合成甲'),
            ClassSite('b', '合成乙')
          ],
          students: const [
            StudentSummary('s', '合成学生')
          ],
          enrollments: [
            Enrollment('e',
                studentId: 's',
                locationId: 'a',
                startDate: oct,
                endDateExclusive: BusinessDate('9999-12-31'))
          ]));
  tearDown(() => repo.dispose());
  test('month paging excludes pre-entry classes and keeps unmarked pending',
      () async {
    repo.sessions = [
      for (final day in ['2026-10-01', '2026-10-02', '2026-10-03'])
        ClassSession('a', BusinessDate(day), SessionStatus.held)
    ];
    repo.records = [
      attendance('2026-10-01', 'a', 'absent'),
      attendance('2026-10-02', 'a', 'attend')
    ];
    final history =
        await StudentHistoryService(repo).watchMonth('s', oct).first;
    expect(history.statistics.expected, 2);
    expect(history.statistics.confirmed, 1);
    expect(history.statistics.rate, 1);
    expect(history.statistics.isFinal, isFalse);
    expect(history.unknownEnrollmentCoverage,
        isTrue); // pre-entry orphan record remains visible
    expect(history.attendance.length, 2);
  });
  test('transfer date belongs to exactly one site, cancelled class excluded',
      () async {
    repo.enrollments = [
      Enrollment('old',
          studentId: 's',
          locationId: 'a',
          startDate: oct,
          endDateExclusive: BusinessDate('2026-10-03')),
      Enrollment('new',
          studentId: 's',
          locationId: 'b',
          startDate: BusinessDate('2026-10-03'),
          endDateExclusive: BusinessDate('9999-12-31'))
    ];
    repo.sessions = [
      ClassSession('a', oct, SessionStatus.held),
      ClassSession('a', BusinessDate('2026-10-03'), SessionStatus.held),
      ClassSession('b', BusinessDate('2026-10-03'), SessionStatus.held),
      ClassSession('b', BusinessDate('2026-10-04'), SessionStatus.cancelled)
    ];
    repo.records = [
      attendance('2026-10-02', 'a', 'attend'),
      attendance('2026-10-03', 'b', 'absent')
    ];
    final history =
        await StudentHistoryService(repo).watchMonth('s', oct).first;
    expect(history.statistics.expected, 2);
    expect(history.statistics.rate, .5);
    expect(history.statistics.isFinal, isTrue);
  });
  test('legacy scores remain excluded after confirming only a remark',
      () async {
    repo.records = [
      DailyRecord('performance',
          studentId: 's',
          locationId: 'a',
          date: oct,
          provenance: 'partiallyConfirmed',
          confirmedFields: [
            'remarks'
          ],
          values: {
            'mathPerformanceRating': 3,
            'performanceRating': 'average',
            'remarks': '已核對備註'
          })
    ];
    final history =
        await StudentHistoryService(repo).watchMonth('s', oct).first;
    expect(history.average('mathPerformanceRating'), isNull);
    expect(history.confirmedRatings, 0);
  });
  test('only confirmed individual metrics enter an average', () async {
    repo.records = [
      DailyRecord('performance',
          studentId: 's',
          locationId: 'a',
          date: oct,
          provenance: 'partiallyConfirmed',
          confirmedFields: ['mathPerformanceRating'],
          values: {'mathPerformanceRating': 5, 'chinesePerformanceRating': 3})
    ];
    final history =
        await StudentHistoryService(repo).watchMonth('s', oct).first;
    expect(history.average('mathPerformanceRating'), 5);
    expect(history.average('chinesePerformanceRating'), isNull);
  });
  test('unknown enrollment baseline is marked incomplete before baseline',
      () async {
    repo.enrollments = [
      Enrollment('e',
          studentId: 's',
          locationId: 'a',
          startDate: oct,
          startKnown: false,
          endDateExclusive: BusinessDate('9999-12-31'))
    ];
    final history = await StudentHistoryService(repo)
        .watchMonth('s', BusinessDate('2026-09-01'))
        .first;
    expect(history.unknownEnrollmentCoverage, isTrue);
    expect(history.statistics.rate, isNull);
  });
  test('recent records are bounded and sorted across authorized sites',
      () async {
    repo.records = [
      for (var i = 1; i <= 20; i++)
        DailyRecord('performance',
            studentId: 's',
            locationId: i.isEven ? 'a' : 'b',
            date: BusinessDate.fromCalendar(DateTime(2026, 9, i)),
            values: {})
    ];
    final rows =
        await StudentHistoryService(repo).watchRecent('s', limit: 5).first;
    expect(rows.length, 5);
    expect(rows.first.date.value, '2026-09-20');
    expect(rows.last.date.value, '2026-09-16');
  });
  test(
      'confirmed orphan scores stay visible without entering enrollment averages',
      () async {
    repo.records = [
      DailyRecord('performance',
          studentId: 's',
          locationId: 'a',
          date: BusinessDate('2026-10-01'),
          values: {
            'mathPerformanceRating': 5,
            'performanceRating': 'excellent'
          })
    ];
    final history =
        await StudentHistoryService(repo).watchMonth('s', oct).first;
    expect(history.performance.length, 1);
    expect(history.average('mathPerformanceRating'), isNull);
    expect(history.confirmedRatings, 0);
    expect(history.unknownEnrollmentCoverage, isTrue);
  });
}
