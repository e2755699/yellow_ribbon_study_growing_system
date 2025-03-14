import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';

import 'package:yellow_ribbon_study_growing_system/domain/model/daily_attendance/student_daily_attendance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/utils/date_formatter.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_util.dart';

class DailyAttendanceRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Helper method to generate document ID
  String _getDocumentId(DateTime date, ClassLocation classLocation) {
    return DateFormatter.formatToDocId(date, classLocation.name);
  }

  /// Load DailyAttendanceInfo from Firestore by ID
  /// If document does not exist, create a new one with default data
  Future<DailyAttendanceInfo> load(
      DateTime date, ClassLocation classLocation) async {
    final documentId = _getDocumentId(date, classLocation);

    try {
      final docRef = _firestore.collection('daily_attendance').doc(documentId);
      final doc = await docRef.get();

      if (doc.exists) {
        // If document exists, parse the data
        final data = doc.data()!;
        return DailyAttendanceInfo.fromFirebase(data, documentId);
      } else {
        // If document does not exist, create a new default document
        var students = await GetIt.I<StudentsRepo>().load();
        final defaultInfo = DailyAttendanceInfo(
            date,
            classLocation,
            students
                .where((student) => student.classLocation == classLocation.name)
                .map(
                  (student) => StudentDailyAttendanceRecord.create(student),
                )
                .toList());
        await docRef.set(defaultInfo.toFirebase());
        return defaultInfo;
      }
    } catch (e, st) {
      print('Error loading DailyAttendanceInfo: $e $st');
      throw Exception('Failed to load DailyAttendanceInfo');
    }
  }

  Future<void> save(DailyAttendanceInfo dailyAttendanceInfo) async {
    final documentId = _getDocumentId(
        dailyAttendanceInfo.date, dailyAttendanceInfo.classLocation);
    try {
      final docRef = _firestore.collection('daily_attendance').doc(documentId);

      final existingDoc = await docRef.get();
      if (existingDoc.exists) {
        // Update existing document
        await docRef.update(dailyAttendanceInfo.toFirebase());
      } else {
        // Create new document
        await docRef.set(dailyAttendanceInfo.toFirebase());
      }
    } catch (e) {
      print('Error saving DailyAttendanceInfo: $e');
    }
  }

  /// Delete DailyAttendanceInfo from Firestore by ID
  Future<void> delete(DateTime date, ClassLocation classLocation) async {
    try {
      var id = _getDocumentId(date, classLocation);
      await _firestore.collection('daily_attendance').doc(id).delete();
    } catch (e) {
      print("Error deleting DailyAttendanceInfo: $e");
    }
  }
}
