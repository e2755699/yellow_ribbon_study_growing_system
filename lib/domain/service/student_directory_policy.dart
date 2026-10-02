import '../model/student/student_detail.dart';

class StudentDirectoryPolicy {
  static List<StudentDetail> filter(List<StudentDetail> students,
      {String locationId = '',
      String search = '',
      bool includeArchived = false}) {
    final query = search.trim().toLowerCase();
    return students
        .where((student) =>
            (includeArchived || !student.archived) &&
            (locationId.isEmpty || student.locationId == locationId) &&
            (query.isEmpty ||
                student.name.toLowerCase().contains(query) ||
                student.school.toLowerCase().contains(query)))
        .toList();
  }
}
