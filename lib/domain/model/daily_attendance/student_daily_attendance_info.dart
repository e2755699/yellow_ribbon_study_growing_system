import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/daily_attendance_page/daily_attendance_page_widget.dart';

class DailyAttendanceInfo {
  final DateTime date;
  final ClassLocation classLocation;

  //todo 是不是要用map sid , record
  final List<StudentDailyAttendanceRecord> records;

  DailyAttendanceInfo(this.date, this.classLocation, this.records);

  /// Convert Firestore data to DailyAttendanceInfo
  static DailyAttendanceInfo fromFirebase(
      Map<String, dynamic> data, String id) {
    final classLocation = ClassLocation.fromString(data['classLocation']);

    final date = DateTime.fromMillisecondsSinceEpoch(
        (data['date'] as Timestamp).millisecondsSinceEpoch);
    final records = (data['records'] as List<dynamic>? ?? [])
        .map((recordData) => StudentDailyAttendanceRecord.fromFirebase(
            recordData, classLocation))
        .toList();

    return DailyAttendanceInfo(date, classLocation, records);
  }

  /// Convert DailyAttendanceInfo to Firestore data
  Map<String, dynamic> toFirebase() {
    return {
      'date': date,
      'classLocation': classLocation.name,
      'records': records.map((record) => record.toFirebase()).toList(),
    };
  }
}

class StudentDailyAttendanceRecord {
  final String sid;
  final String name;
  final ClassLocation classLocation;
  final ValueNotifier<AttendanceStatus> attendanceStatusNotifier;
  final ValueNotifier<String> leaveReasonNotifier;

  StudentDailyAttendanceRecord(this.sid, this.name, this.classLocation, status, {String leaveReason = ""})
      : attendanceStatusNotifier = ValueNotifier(status),
        leaveReasonNotifier = ValueNotifier(leaveReason);

  factory StudentDailyAttendanceRecord.create(StudentDetail student) {
    return StudentDailyAttendanceRecord(
      student.id!,
      student.name,
      ClassLocation.fromString(student.classLocation),
      AttendanceStatus.absent,
    );
  }

  /// Convert Firestore data to StudentDailyAttendanceRecord
  static StudentDailyAttendanceRecord fromFirebase(
      Map<String, dynamic> data, ClassLocation classLocation) {
    return StudentDailyAttendanceRecord(
        data['sid'] as String,
        data['name'] as String,
        classLocation,
        AttendanceStatus.fromString(data['status'] as String? ?? "absent"),
        leaveReason: data['leaveReason'] as String? ?? "");
  }

  /// Convert StudentDailyAttendanceRecord to Firebase data
  Map<String, dynamic> toFirebase() {
    return {
      'sid': sid,
      'name': name,
      'classLocation': classLocation.name,
      'status': attendanceStatusNotifier.value.name,
      'leaveReason': leaveReasonNotifier.value,
    };
  }
}
