import 'roster_models.dart';

class RosterAccess {
  final String uid, role;
  final List<String> locationIds;
  final bool enabled;
  RosterAccess(this.uid, this.role, List<String> locationIds,
      {this.enabled = true})
      : locationIds = List.unmodifiable(locationIds);
  bool get isManager => role == 'manager' || role == 'owner';
}

abstract class RosterRepository {
  Stream<RosterAccess?> watchAccess();
  Stream<List<ClassSite>> watchSites();
  Stream<DataSnapshot<List<StudentSummary>>> watchStudents(String locationId);
  Stream<DataSnapshot<List<Enrollment>>> watchEnrollments(String locationId,
      {BusinessDate? date, String? studentId});
  Stream<DataSnapshot<List<DailyRecord>>> watchRecords(
      String kind, String locationId,
      {BusinessDate? date,
      String? studentId,
      BusinessDate? from,
      BusinessDate? to,
      int limit = 100,
      String? beforeDate});
  Stream<DataSnapshot<List<ClassSession>>> watchSessions(
      String locationId, BusinessDate from, BusinessDate to);
  Future<Map<String, dynamic>> command(Map<String, dynamic> payload);
}
