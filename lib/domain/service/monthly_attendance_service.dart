import 'dart:async';
import '../model/roster/monthly_attendance_report.dart';
import '../model/roster/roster_models.dart';
import '../repo/roster_repository.dart';

class MonthlyAttendanceService {
  const MonthlyAttendanceService(this.repository);
  final RosterRepository repository;

  Stream<MonthlyAttendanceReport> watch(DateTime month, ClassSite site) =>
      Stream.multi((out) {
        final first =
            BusinessDate.fromCalendar(DateTime(month.year, month.month));
        final last =
            BusinessDate.fromCalendar(DateTime(month.year, month.month + 1, 0));
        DataSnapshot<List<StudentSummary>>? students;
        DataSnapshot<List<Enrollment>>? enrollments;
        DataSnapshot<List<DailyRecord>>? records;
        DataSnapshot<List<ClassSession>>? sessions;
        void publish() {
          if (students == null ||
              enrollments == null ||
              records == null ||
              sessions == null) {
            return;
          }
          try {
            out.addSync(build(
                month: month,
                site: site,
                students: students!.data,
                enrollments: enrollments!.data,
                records: records!.data,
                sessions: sessions!.data,
                fromCache: students!.fromCache ||
                    enrollments!.fromCache ||
                    records!.fromCache ||
                    sessions!.fromCache));
          } catch (error, stack) {
            out.addErrorSync(error, stack);
          }
        }

        final subscriptions = <StreamSubscription<dynamic>>[
          repository.watchStudents(site.id).listen((data) {
            students = data;
            publish();
          }, onError: (Object error, StackTrace stack) {
            students = null;
            out.addErrorSync(error, stack);
          }),
          repository.watchEnrollments(site.id).listen((data) {
            enrollments = data;
            publish();
          }, onError: (Object error, StackTrace stack) {
            enrollments = null;
            out.addErrorSync(error, stack);
          }),
          repository
              .watchRecords('attendance', site.id,
                  from: first, to: last, limit: null)
              .listen((data) {
            records = data;
            publish();
          }, onError: (Object error, StackTrace stack) {
            records = null;
            out.addErrorSync(error, stack);
          }),
          repository.watchSessions(site.id, first, last).listen((data) {
            sessions = data;
            publish();
          }, onError: (Object error, StackTrace stack) {
            sessions = null;
            out.addErrorSync(error, stack);
          }),
        ];
        out.onCancel = () async {
          for (final subscription in subscriptions) {
            await subscription.cancel();
          }
        };
      });

  static MonthlyAttendanceReport build(
      {required DateTime month,
      required ClassSite site,
      required List<StudentSummary> students,
      required List<Enrollment> enrollments,
      required List<DailyRecord> records,
      required List<ClassSession> sessions,
      bool fromCache = false}) {
    final start = BusinessDate.fromCalendar(DateTime(month.year, month.month));
    final end =
        BusinessDate.fromCalendar(DateTime(month.year, month.month + 1));
    final periods = enrollments
        .where((e) =>
            e.locationId == site.id &&
            e.startDate.compareTo(e.endDateExclusive) < 0 &&
            e.startDate.compareTo(end) < 0 &&
            e.endDateExclusive.compareTo(start) > 0)
        .toList();
    final monthRecords = records
        .where((r) =>
            r.kind == 'attendance' &&
            r.locationId == site.id &&
            r.date.compareTo(start) >= 0 &&
            r.date.compareTo(end) < 0)
        .toList();
    final monthSessions = {
      for (final s in sessions.where((s) =>
          s.locationId == site.id &&
          s.date.compareTo(start) >= 0 &&
          s.date.compareTo(end) < 0))
        s.date.value: s
    };
    final profiles = {for (final student in students) student.id: student.name};
    final ids = {
      ...periods.map((e) => e.studentId),
      ...monthRecords.map((r) => r.studentId)
    };
    final rows = <MonthlyAttendanceRow>[];
    for (final sid in ids) {
      final studentRecords = {
        for (final r in monthRecords.where((r) => r.studentId == sid))
          r.date.value: r
      };
      var expected = 0,
          present = 0,
          sick = 0,
          personal = 0,
          otherLeave = 0,
          absent = 0,
          bus = 0,
          missing = 0,
          pending = 0,
          uncertain = 0;
      final days = <MonthlyAttendanceDay>[];
      for (var day = 1;
          day <= DateTime(month.year, month.month + 1, 0).day;
          day++) {
        final date =
            BusinessDate.fromCalendar(DateTime(month.year, month.month, day));
        final eligible =
            periods.any((e) => e.studentId == sid && e.includes(date));
        final session = monthSessions[date.value];
        final held = session?.status == SessionStatus.held;
        final row = studentRecords[date.value];
        if (eligible && held) expected++;
        if (row == null) {
          if (eligible && held) {
            missing++;
            days.add(const MonthlyAttendanceDay('', '無點名紀錄', expected: true));
          } else {
            days.add(MonthlyAttendanceDay(
                '',
                session?.status == SessionStatus.cancelled
                    ? '課次已取消'
                    : eligible
                        ? '無點名紀錄'
                        : '不在有效就讀期間'));
          }
          continue;
        }
        final status = row.values['status'];
        final reason = (row.values['leaveReason'] as String? ?? '').trim();
        final symbol = switch (status) {
          'attend' => '○',
          'late' => '遲',
          'earlyLeave' => '早',
          'absent' => '×',
          'busAbsent' => '車',
          'leave' => reason == '病假'
              ? '＋'
              : reason == '事假'
                  ? '△'
                  : '請',
          _ => status?.toString() ?? ''
        };
        // Report existing values as recorded. Migration provenance and missing
        // session/enrollment metadata do not invalidate real attendance.
        {
          switch (status) {
            case 'attend':
            case 'late':
            case 'earlyLeave':
              present++;
            case 'leave':
              if (reason == '病假') {
                sick++;
              } else if (reason == '事假') {
                personal++;
              } else {
                otherLeave++;
              }
            case 'absent':
              absent++;
            case 'busAbsent':
              bus++;
          }
        }
        days.add(MonthlyAttendanceDay(symbol,
            [status?.toString() ?? '', if (reason.isNotEmpty) reason].join('；'),
            expected: eligible && held));
      }
      final snapshots = studentRecords.values.toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final name = profiles[sid] ??
          snapshots
              .map((r) => r.nameSnapshot)
              .where((name) => name.isNotEmpty)
              .firstOrNull ??
          '歷史學生（姓名待核對）';
      rows.add(MonthlyAttendanceRow(
          studentId: sid,
          name: name,
          days: List.unmodifiable(days),
          expected: expected,
          present: present,
          sick: sick,
          personal: personal,
          otherLeave: otherLeave,
          absent: absent,
          busAbsent: bus,
          missing: missing,
          pending: pending,
          uncertainSessions: uncertain));
    }
    rows.sort((a, b) {
      final name = a.name.compareTo(b.name);
      return name == 0 ? a.studentId.compareTo(b.studentId) : name;
    });
    return MonthlyAttendanceReport(
        month: DateTime(month.year, month.month),
        site: site,
        rows: List.unmodifiable(rows),
        recordCount: monthRecords.length,
        sessionCount: monthSessions.values
            .where((s) => s.status == SessionStatus.held)
            .length,
        fromCache: fromCache);
  }
}
