import '../utils/subscription_failure.dart';
import 'package:stream_transform/stream_transform.dart';
import '../model/roster/roster_models.dart';
import 'roster_policy.dart';
import '../repo/roster_repository.dart';

class StudentHistory {
  final String studentId, name;
  final BusinessDate from, to;
  final List<ClassSite> sites;
  final List<Enrollment> enrollments;
  final List<DailyRecord> attendance, performance;
  final AttendanceStatistics statistics;
  final bool fromCache, unknownEnrollmentCoverage;
  const StudentHistory(
      {required this.studentId,
      required this.name,
      required this.from,
      required this.to,
      required this.sites,
      required this.enrollments,
      required this.attendance,
      required this.performance,
      required this.statistics,
      required this.fromCache,
      required this.unknownEnrollmentCoverage});
  bool _inEnrollment(DailyRecord record) => enrollments.any((p) =>
      p.studentId == studentId &&
      p.locationId == record.locationId &&
      p.includes(record.date));
  double? average(String field) {
    final values = performance
        .where((r) => _inEnrollment(r) && r.fieldConfirmed(field))
        .map((r) => r.values[field])
        .whereType<int>()
        .where((value) => value >= 1 && value <= 5)
        .toList();
    return values.isEmpty
        ? null
        : values.reduce((a, b) => a + b) / values.length;
  }

  int get confirmedRatings => performance
      .where((r) =>
          _inEnrollment(r) &&
          r.fieldConfirmed('performanceRating') &&
          r.values['performanceRating'] != null)
      .length;
}

class StudentHistoryService {
  final RosterRepository repository;
  const StudentHistoryService(this.repository);

  /// Calendar-month paging bounds each query to at most 31 daily keys per site.
  /// Records are never truncated to an arbitrary last-100 window for statistics.
  Stream<StudentHistory> watchMonth(String sid, BusinessDate month) {
    final from = BusinessDate.fromCalendar(
        DateTime(month.calendar.year, month.calendar.month));
    final to = BusinessDate.fromCalendar(
        DateTime(month.calendar.year, month.calendar.month + 1, 0));
    return repository.watchAccess().switchMap((access) {
      if (access == null) return Stream.error(const SubscriptionAccessDenied());
      if (access.locationIds.isEmpty)
        return Stream.error(const SubscriptionAccessDenied());
      return repository.watchSites().switchMap((sites) {
        if (sites.isEmpty) return Stream.error(StateError('據點資料尚未完整'));
        final streams = <Stream<DataSnapshot<Object>>>[];
        for (final site in sites) {
          streams.addAll([
            repository.watchStudents(site.id),
            repository.watchEnrollments(site.id, studentId: sid),
            repository.watchRecords('attendance', site.id,
                studentId: sid, from: from, to: to, limit: 32),
            repository.watchRecords('performance', site.id,
                studentId: sid, from: from, to: to, limit: 32),
            repository.watchSessions(site.id, from, to),
          ]);
        }
        return streams.first.combineLatestAll(streams.skip(1)).map((values) {
          final periods = <Enrollment>[],
              attendance = <DailyRecord>[],
              performance = <DailyRecord>[],
              sessions = <ClassSession>[];
          String? name;
          for (var i = 0; i < values.length; i += 5) {
            name ??= (values[i].data as List<StudentSummary>)
                .where((s) => s.id == sid)
                .firstOrNull
                ?.name;
            periods.addAll(values[i + 1].data as List<Enrollment>);
            attendance.addAll(values[i + 2].data as List<DailyRecord>);
            performance.addAll(values[i + 3].data as List<DailyRecord>);
            sessions.addAll(values[i + 4].data as List<ClassSession>);
            if ((values[i + 2].data as List).length > 31 ||
                (values[i + 3].data as List).length > 31) {
              throw StateError('單日紀錄重複，統計尚未確認');
            }
          }
          int newest(DailyRecord a, DailyRecord b) => b.id.compareTo(a.id);
          attendance.sort(newest);
          performance.sort(newest);
          return StudentHistory(
              studentId: sid,
              name: name ??
                  (performance.isNotEmpty
                      ? performance.first.nameSnapshot
                      : '歷史學生'),
              from: from,
              to: to,
              sites: List.unmodifiable(sites),
              enrollments: List.unmodifiable(periods),
              attendance: List.unmodifiable(attendance),
              performance: List.unmodifiable(performance),
              statistics: AttendanceStatistics.calculate(
                  studentId: sid,
                  enrollments: periods,
                  sessions: sessions,
                  records: attendance),
              fromCache: values.any((v) => v.fromCache),
              unknownEnrollmentCoverage: periods.any((p) =>
                      !p.startKnown && from.compareTo(p.startDate) < 0) ||
                  [...attendance, ...performance].any((r) => !periods.any((p) =>
                      p.locationId == r.locationId && p.includes(r.date))));
        });
      });
    });
  }

  /// Bounded recent activity, sorted and deduplicated by complete record key.
  Stream<List<DailyRecord>> watchRecent(String sid, {int limit = 10}) =>
      repository.watchAccess().switchMap((access) {
        if (access == null || access.locationIds.isEmpty) {
          return Stream.error(const SubscriptionAccessDenied());
        }
        final streams = [
          for (final id in access.locationIds)
            repository.watchRecords('performance', id,
                studentId: sid, limit: limit)
        ];
        return streams.first.combineLatestAll(streams.skip(1)).map((snapshots) {
          final rows = snapshots.expand((s) => s.data).toList()
            ..sort((a, b) => b.id.compareTo(a.id));
          return List<DailyRecord>.unmodifiable(rows.take(limit));
        });
      });
}
