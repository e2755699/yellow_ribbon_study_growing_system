import 'roster_models.dart';

class RosterPolicy {
  static DailyRosterCounts counts(
      List<RosterMember> members, Map<String, dynamic> Function(String) values,
      {required String kind,
      required bool Function(String, String) confirmed}) {
    final field = kind == 'attendance' ? 'status' : 'performanceRating';
    final marked = members
        .where((m) =>
            values(m.student.id)[field] != null &&
            confirmed(m.student.id, field))
        .length;
    final unverified = members
        .where((m) =>
            values(m.student.id)[field] != null &&
            !confirmed(m.student.id, field))
        .length;
    return DailyRosterCounts(members.length, marked, unverified);
  }

  static List<RosterMember> members(BusinessDate date, String locationId,
      List<Enrollment> enrollments, List<StudentSummary> students) {
    final profiles = {for (final student in students) student.id: student};
    final result = <String, RosterMember>{};
    for (final enrollment in enrollments) {
      if (enrollment.locationId != locationId || !enrollment.includes(date)) {
        continue;
      }
      if (result.containsKey(enrollment.studentId)) {
        throw StateError('同一學生有重疊就讀期間，請先核對');
      }
      final student = profiles[enrollment.studentId];
      if (student == null) throw StateError('名冊缺少學生主檔，資料未完整');
      // An archived profile remains in its historical effective period.
      result[student.id] = RosterMember(student, enrollment);
    }
    return result.values.toList()
      ..sort((a, b) => a.student.id.compareTo(b.student.id));
  }
}

class DailyRosterCounts {
  final int total, marked, unverified;
  const DailyRosterCounts(this.total, this.marked, this.unverified);
  int get unmarked => total - marked - unverified;
}

class AttendanceStatistics {
  final int expected, confirmed, present, uncertainSessions;
  const AttendanceStatistics(this.expected, this.confirmed, this.present,
      {this.uncertainSessions = 0});
  double? get rate => confirmed == 0 ? null : present / confirmed;
  bool get isFinal =>
      expected > 0 && confirmed == expected && uncertainSessions == 0;

  static AttendanceStatistics calculate(
      {required String studentId,
      required List<Enrollment> enrollments,
      required List<ClassSession> sessions,
      required List<DailyRecord> records}) {
    final results = {
      for (final row in records)
        if (row.kind == 'attendance' && row.studentId == studentId) row.id: row
    };
    final seen = <String>{};
    var expected = 0, confirmed = 0, present = 0, uncertain = 0;
    for (final session in sessions) {
      if (!seen.add(session.id) || session.status == SessionStatus.cancelled) {
        continue;
      }
      final eligible = enrollments.any((e) =>
          e.studentId == studentId &&
          e.locationId == session.locationId &&
          e.includes(session.date));
      if (!eligible) continue;
      if (session.status == SessionStatus.legacyUnverified) {
        uncertain++;
        continue;
      }
      expected++;
      final row = results[
          [session.date.value, session.locationId, studentId].join('.')];
      if (row == null || !row.fieldConfirmed('status')) continue;
      final status = row.values['status'];
      if (!{'attend', 'late', 'earlyLeave', 'absent', 'leave', 'busAbsent'}
          .contains(status)) {
        continue;
      }
      confirmed++;
      if ({'attend', 'late', 'earlyLeave'}.contains(status)) present++;
    }
    return AttendanceStatistics(expected, confirmed, present,
        uncertainSessions: uncertain);
  }
}
