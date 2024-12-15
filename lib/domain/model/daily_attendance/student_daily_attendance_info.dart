import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/daily_attendance_page/daily_attendance_page_widget.dart';

class StudentDailyAttendanceInfo {
  final int id;
  final String name;
  final ClassLocation classLocation;
  final ValueNotifier<AttendanceStatus> attendanceStatusNotifier =
      ValueNotifier(AttendanceStatus.attend);

  StudentDailyAttendanceInfo(this.id, this.name, this.classLocation);
}
