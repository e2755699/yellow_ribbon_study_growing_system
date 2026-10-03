import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/attendance_status.dart';

class StudentDailyAttendanceRecord {
  final String sid;
  final String name;
  final ClassLocation classLocation;
  final ValueNotifier<AttendanceStatus> attendanceStatusNotifier;
  final ValueNotifier<String> leaveReasonNotifier;

  StudentDailyAttendanceRecord(this.sid, this.name, this.classLocation, status,
      {String leaveReason = ""})
      : attendanceStatusNotifier = ValueNotifier(status),
        leaveReasonNotifier = ValueNotifier(leaveReason);
}
