import 'package:stream_transform/stream_transform.dart';
import '../model/roster/roster_models.dart';
import 'roster_policy.dart';
import '../repo/roster_repository.dart';

class DailyRosterService {
  final RosterRepository repository;
  const DailyRosterService(this.repository);

  Stream<DailyRoster> watch(BusinessDate date, String locationId) {
    // Wait for every source before publishing counts. Never turn errors into [].
    final streams = <Stream<DataSnapshot<Object>>>[
      repository.watchStudents(locationId),
      repository.watchEnrollments(locationId, date: date),
      repository.watchRecords('attendance', locationId, date: date),
      repository.watchRecords('performance', locationId, date: date),
      repository.watchSessions(locationId, date, date),
    ];
    return streams.first.combineLatestAll(streams.skip(1)).map((values) {
      final students = values[0].data as List<StudentSummary>;
      final enrollments = values[1].data as List<Enrollment>;
      final attendance = values[2].data as List<DailyRecord>;
      final performance = values[3].data as List<DailyRecord>;
      final sessions = values[4].data as List<ClassSession>;
      return DailyRoster(
        date: date,
        locationId: locationId,
        members: RosterPolicy.members(date, locationId, enrollments, students),
        attendance: {for (final row in attendance) row.studentId: row},
        performance: {for (final row in performance) row.studentId: row},
        session: sessions.isEmpty ? null : sessions.single,
        fromCache: values.any((value) => value.fromCache),
      );
    });
  }
}
