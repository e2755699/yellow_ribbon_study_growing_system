import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/excellent_character.dart';
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
            recordData, classLocation,
            date: recordDate))
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
  final ValueNotifier<String> remarksNotifier;
  final DateTime recordDate;

  // 新增欄位 - 五度量表評分
  final ValueNotifier<int> classPerformanceRatingNotifier; // 上課表現
  final ValueNotifier<int> mathPerformanceRatingNotifier; // 數學成績
  final ValueNotifier<int> chinesePerformanceRatingNotifier; // 國文成績
  final ValueNotifier<int> englishPerformanceRatingNotifier; // 英文成績
  final ValueNotifier<int> socialPerformanceRatingNotifier; // 社會成績

  // 優秀品格標籤
  final ValueNotifier<List<ExcellentCharacter>> excellentCharactersNotifier;
  
  // 完成作業和小幫手的計算屬性
  bool get homeworkCompleted => 
      excellentCharactersNotifier.value.contains(ExcellentCharacter.homeworkCompleted);
  
  bool get isHelper => 
      excellentCharactersNotifier.value.contains(ExcellentCharacter.helper);
  
  // 設置完成作業狀態
  void setHomeworkCompleted(bool value) {
    final updatedTags = List<ExcellentCharacter>.from(excellentCharactersNotifier.value);
    if (value && !updatedTags.contains(ExcellentCharacter.homeworkCompleted)) {
      updatedTags.add(ExcellentCharacter.homeworkCompleted);
    } else if (!value) {
      updatedTags.remove(ExcellentCharacter.homeworkCompleted);
    }
    excellentCharactersNotifier.value = updatedTags;
  }
  
  // 設置小幫手狀態
  void setHelper(bool value) {
    final updatedTags = List<ExcellentCharacter>.from(excellentCharactersNotifier.value);
    if (value && !updatedTags.contains(ExcellentCharacter.helper)) {
      updatedTags.add(ExcellentCharacter.helper);
    } else if (!value) {
      updatedTags.remove(ExcellentCharacter.helper);
    }
    excellentCharactersNotifier.value = updatedTags;
  }

  StudentDailyPerformanceRecord(
    this.sid,
    this.name,
    this.classLocation,
    PerformanceRating performanceRating, {
    bool homeworkCompleted = false,
    bool isHelper = false,
    String remarks = "",
    DateTime? recordDate,
    int classPerformanceRating = 3,
    int mathPerformanceRating = 3,
    int chinesePerformanceRating = 3,
    int englishPerformanceRating = 3,
    int socialPerformanceRating = 3,
    List<ExcellentCharacter>? excellentCharacters,
  })  : performanceRatingNotifier = ValueNotifier(performanceRating),
        remarksNotifier = ValueNotifier(remarks),
        recordDate = recordDate ?? DateTime.now(),
        classPerformanceRatingNotifier = ValueNotifier(classPerformanceRating),
        mathPerformanceRatingNotifier = ValueNotifier(mathPerformanceRating),
        chinesePerformanceRatingNotifier =
            ValueNotifier(chinesePerformanceRating),
        englishPerformanceRatingNotifier =
            ValueNotifier(englishPerformanceRating),
        socialPerformanceRatingNotifier =
            ValueNotifier(socialPerformanceRating),
        excellentCharactersNotifier = ValueNotifier(excellentCharacters ?? []) {
    // 初始化時設置特殊標籤
    final tags = excellentCharactersNotifier.value.toList();
    if (homeworkCompleted && !tags.contains(ExcellentCharacter.homeworkCompleted)) {
      tags.add(ExcellentCharacter.homeworkCompleted);
    }
    if (isHelper && !tags.contains(ExcellentCharacter.helper)) {
      tags.add(ExcellentCharacter.helper);
    }
    if (tags.length > excellentCharactersNotifier.value.length) {
      excellentCharactersNotifier.value = tags;
    }
  }

  factory StudentDailyPerformanceRecord.create(StudentDetail student,
      {DateTime? date}) {
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
      Map<String, dynamic> data, ClassLocation classLocation,
      {DateTime? date}) {
    // 處理優秀品格列表
    List<ExcellentCharacter> excellentCharacters = [];
    if (data['excellentCharacters'] != null) {
      excellentCharacters = ExcellentCharacter.fromList(
          List<String>.from(data['excellentCharacters']));
    }

    // 這裡不再需要單獨讀取homeworkCompleted和isHelper，因為它們已整合到excellentCharacters中
    return StudentDailyPerformanceRecord(
      data['sid'] as String,
      data['name'] as String,
      classLocation,
      PerformanceRating.fromString(
          data['performanceRating'] as String? ?? "average"),
      remarks: data['remarks'] as String? ?? "",
      recordDate: date,
      classPerformanceRating: data['classPerformanceRating'] as int? ?? 3,
      mathPerformanceRating: data['mathPerformanceRating'] as int? ?? 3,
      chinesePerformanceRating: data['chinesePerformanceRating'] as int? ?? 3,
      englishPerformanceRating: data['englishPerformanceRating'] as int? ?? 3,
      socialPerformanceRating: data['socialPerformanceRating'] as int? ?? 3,
      excellentCharacters: excellentCharacters,
    );
  }

  /// 将 StudentDailyPerformanceRecord 转换为 Firestore 数据
  Map<String, dynamic> toFirebase() {
    return {
      'sid': sid,
      'name': name,
      'classLocation': classLocation.name,
      'performanceRating': performanceRatingNotifier.value.name,
      'remarks': remarksNotifier.value,
      'classPerformanceRating': classPerformanceRatingNotifier.value,
      'mathPerformanceRating': mathPerformanceRatingNotifier.value,
      'chinesePerformanceRating': chinesePerformanceRatingNotifier.value,
      'englishPerformanceRating': englishPerformanceRatingNotifier.value,
      'socialPerformanceRating': socialPerformanceRatingNotifier.value,
      'excellentCharacters': excellentCharactersNotifier.value
          .map((character) => character.name)
          .toList(),
    };
  }
}
