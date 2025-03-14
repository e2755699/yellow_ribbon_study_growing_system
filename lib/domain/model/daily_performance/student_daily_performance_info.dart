import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/performance_rating.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/utils/date_formatter.dart';

class DailyPerformanceInfo {
  final DateTime date;
  final ClassLocation classLocation;
  final List<StudentDailyPerformanceRecord> records;

  DailyPerformanceInfo(this.date, this.classLocation, this.records);

  /// 从 Firestore 数据转换为 DailyPerformanceInfo
  static DailyPerformanceInfo fromFirebase(
      Map<String, dynamic> data, String id) {
    final classLocation = ClassLocation.fromString(data['classLocation']);

    final date = DateTime.fromMillisecondsSinceEpoch(
        (data['date'] as Timestamp).millisecondsSinceEpoch);
        
    // 从文档ID中提取日期
    final recordDate = DateFormatter.extractDateFromDocId(id) ?? date;
    
    final records = (data['records'] as List<dynamic>? ?? [])
        .map((recordData) => StudentDailyPerformanceRecord.fromFirebase(
            recordData, classLocation, date: recordDate))
        .toList();

    return DailyPerformanceInfo(date, classLocation, records);
  }

  /// 将 DailyPerformanceInfo 转换为 Firestore 数据
  Map<String, dynamic> toFirebase() {
    return {
      'date': date,
      'classLocation': classLocation.name,
      'records': records.map((record) => record.toFirebase()).toList(),
    };
  }
}

class StudentDailyPerformanceRecord {
  final String sid;
  final String name;
  final ClassLocation classLocation;
  final ValueNotifier<PerformanceRating> performanceRatingNotifier;
  final ValueNotifier<bool> homeworkCompletedNotifier;
  final ValueNotifier<bool> isHelperNotifier;
  final ValueNotifier<String> remarksNotifier;
  final DateTime recordDate;

  StudentDailyPerformanceRecord(
    this.sid,
    this.name,
    this.classLocation,
    PerformanceRating performanceRating, {
    bool homeworkCompleted = false,
    bool isHelper = false,
    String remarks = "",
    DateTime? recordDate,
  })  : performanceRatingNotifier = ValueNotifier(performanceRating),
        homeworkCompletedNotifier = ValueNotifier(homeworkCompleted),
        isHelperNotifier = ValueNotifier(isHelper),
        remarksNotifier = ValueNotifier(remarks),
        recordDate = recordDate ?? DateTime.now();

  factory StudentDailyPerformanceRecord.create(StudentDetail student, {DateTime? date}) {
    return StudentDailyPerformanceRecord(
      student.id!,
      student.name,
      ClassLocation.fromString(student.classLocation),
      PerformanceRating.average,
      recordDate: date,
    );
  }

  /// 从 Firestore 数据转换为 StudentDailyPerformanceRecord
  static StudentDailyPerformanceRecord fromFirebase(
      Map<String, dynamic> data, ClassLocation classLocation, {DateTime? date}) {
    return StudentDailyPerformanceRecord(
      data['sid'] as String,
      data['name'] as String,
      classLocation,
      PerformanceRating.fromString(
          data['performanceRating'] as String? ?? "average"),
      homeworkCompleted: data['homeworkCompleted'] as bool? ?? false,
      isHelper: data['isHelper'] as bool? ?? false,
      remarks: data['remarks'] as String? ?? "",
      recordDate: date,
    );
  }

  /// 将 StudentDailyPerformanceRecord 转换为 Firestore 数据
  Map<String, dynamic> toFirebase() {
    return {
      'sid': sid,
      'name': name,
      'classLocation': classLocation.name,
      'performanceRating': performanceRatingNotifier.value.name,
      'homeworkCompleted': homeworkCompletedNotifier.value,
      'isHelper': isHelperNotifier.value,
      'remarks': remarksNotifier.value,
    };
  }
} 