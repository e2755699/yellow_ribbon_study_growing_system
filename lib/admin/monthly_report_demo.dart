import '../domain/model/roster/roster_models.dart';
import '../domain/repo/memory_roster_repository.dart';
import '../domain/repo/roster_repository.dart';

/// Synthetic fixtures only. Never derived from production exports or names.
MemoryRosterRepository monthlyReportDemoRepository(
    {DateTime? month, int count = 12}) {
  final selected = month ?? DateTime(2026, 10);
  final first =
      BusinessDate.fromCalendar(DateTime(selected.year, selected.month));
  final last =
      BusinessDate.fromCalendar(DateTime(selected.year, selected.month + 1));
  const sites = [
    ClassSite('sample-east', '示範東區據點'),
    ClassSite('sample-west', '示範西區據點')
  ];
  final students = List.generate(
      count,
      (i) => StudentSummary(
          'sample-${i + 1}', '示範同學${(i + 1).toString().padLeft(2, '0')}'));
  final enrollments = [
    for (final site in sites)
      for (final student in students)
        Enrollment('${site.id}-${student.id}',
            studentId: student.id,
            locationId: site.id,
            startDate: first,
            endDateExclusive: last)
  ];
  final sessions = <ClassSession>[];
  final records = <DailyRecord>[];
  for (final site in sites) {
    for (var d = 1;
        d <= DateTime(selected.year, selected.month + 1, 0).day;
        d++) {
      final date = DateTime(selected.year, selected.month, d);
      if (date.weekday >= 6) continue;
      final day = BusinessDate.fromCalendar(date);
      sessions.add(ClassSession(site.id, day, SessionStatus.held));
      for (var i = 0; i < students.length; i++) {
        if (d == 5 && i == 2) continue;
        final status = (i + d) % 19 == 0
            ? 'absent'
            : (i + d) % 13 == 0
                ? 'leave'
                : 'attend';
        records.add(DailyRecord('attendance',
            studentId: students[i].id,
            locationId: site.id,
            date: day,
            nameSnapshot: students[i].name,
            provenance: d == 1 && i == 0 ? 'legacyUnverified' : 'confirmed',
            values: {
              'status': status,
              if (status == 'leave') 'leaveReason': i.isEven ? '病假' : '事假'
            }));
      }
    }
  }
  return MemoryRosterRepository(
      access:
          RosterAccess('sample', 'manager', sites.map((s) => s.id).toList()),
      sites: sites,
      students: students,
      enrollments: enrollments,
      sessions: sessions,
      records: records);
}
