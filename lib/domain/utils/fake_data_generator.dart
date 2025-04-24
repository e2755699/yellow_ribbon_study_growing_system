import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/performance_rating.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_attendance/student_daily_attendance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_performance/student_daily_performance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_attendance_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_performance_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/daily_attendance_page/daily_attendance_page_widget.dart';

/// 假数据生成器
class FakeDataGenerator {
  final Random _random = Random();
  final StudentsRepo _studentsRepo;
  final DailyAttendanceRepo _dailyAttendanceRepo;
  final DailyPerformanceRepo _dailyPerformanceRepo;

  // 学校列表
  final List<String> _schools = [
    '台北市立第一中學',
    '台北市立第二中學',
    '台北市立第三中學',
    '新北市立第一中學',
    '新北市立第二中學',
    '新北市立第三中學',
    '桃園市立第一中學',
    '桃園市立第二中學',
    '桃園市立第三中學',
    '台中市立第一中學',
    '台中市立第二中學',
    '台中市立第三中學',
    '高雄市立第一中學',
    '高雄市立第二中學',
    '高雄市立第三中學',
  ];

  // 姓氏列表
  final List<String> _lastNames = [
    '陳',
    '林',
    '黃',
    '張',
    '李',
    '王',
    '吳',
    '劉',
    '蔡',
    '楊',
    '許',
    '鄭',
    '謝',
    '郭',
    '洪',
    '曾',
    '周',
    '蘇',
    '葉',
    '呂',
  ];

  // 名字列表
  final List<String> _firstNames = [
    '志明',
    '俊傑',
    '建宏',
    '文雄',
    '志豪',
    '志偉',
    '志強',
    '家豪',
    '志成',
    '志華',
    '美玲',
    '淑芬',
    '淑惠',
    '美惠',
    '美華',
    '麗華',
    '淑華',
    '美玉',
    '麗娟',
    '淑娟',
  ];

  // 表现描述列表
  final List<String> _remarks = [
    '上課認真聽講，積極參與討論',
    '作業完成度高，但有些小錯誤',
    '上課有時會分心，需要提醒',
    '能夠幫助其他同學解決問題',
    '課堂表現優秀，思考活躍',
    '作業經常遲交，但質量不錯',
    '上課專注度有待提高',
    '積極回答問題，思路清晰',
    '作業完成情況不穩定',
    '上課偶爾會和同學聊天',
    '能夠主動提出問題',
    '作業完成度高，且質量優秀',
    '上課表現積極，但有時會打斷他人',
    '能夠認真完成老師布置的任務',
    '需要更多的課後輔導',
  ];

  FakeDataGenerator()
      : _studentsRepo = GetIt.I<StudentsRepo>(),
        _dailyAttendanceRepo = GetIt.I<DailyAttendanceRepo>(),
        _dailyPerformanceRepo = GetIt.I<DailyPerformanceRepo>();

  /// 生成所有假数据
  Future<void> generateAllFakeData() async {
    print('開始生成假數據...');

    // 生成各据点的学生
    await _generateStudents();

    // 生成两个月的出勤记录和表现记录
    await _generateAttendanceAndPerformanceRecords();

    print('假數據生成完成！');
  }

  /// 生成各据点的学生
  Future<void> _generateStudents() async {
    print('生成學生數據...');

    // 获取所有学生，检查是否已经有足够的学生
    final existingStudents = await _studentsRepo.load();
    if (existingStudents.length >= ClassLocation.values.length * 30) {
      print('已有足夠的學生數據，跳過生成');
      return;
    }

    // 为每个据点生成30位学生
    for (var location in ClassLocation.values) {
      for (var i = 0; i < 30; i++) {
        final student = _createRandomStudent(location);
        await _studentsRepo.create(student);
      }
    }

    print('學生數據生成完成');
  }

  /// 生成两个月的出勤记录和表现记录
  Future<void> _generateAttendanceAndPerformanceRecords() async {
    print('生成出勤和表現記錄...');

    // 获取所有学生
    final students = await _studentsRepo.load();
    if (students.isEmpty) {
      print('沒有學生數據，無法生成記錄');
      return;
    }

    // 获取当前日期
    final now = DateTime.now();

    // 生成过去两个月的记录（每周5天，周一到周五）
    final startDate = DateTime(now.year, now.month - 2, now.day);

    // 按据点分组学生
    final Map<String, List<StudentDetail>> studentsByLocation = {};
    for (var student in students) {
      if (!studentsByLocation.containsKey(student.classLocation)) {
        studentsByLocation[student.classLocation] = [];
      }
      studentsByLocation[student.classLocation]!.add(student);
    }

    // 生成每天的记录
    for (var date = startDate;
        date.isBefore(now);
        date = date.add(const Duration(days: 1))) {
      // 跳过周末
      if (date.weekday > 5) continue;

      // 为每个据点生成记录
      for (var locationName in studentsByLocation.keys) {
        final location = ClassLocation.fromString(locationName);
        final studentsInLocation = studentsByLocation[locationName]!;

        // 生成出勤记录
        await _generateDailyAttendance(date, location, studentsInLocation);

        // 生成表现记录
        await _generateDailyPerformance(date, location, studentsInLocation);
      }
    }

    print('出勤和表現記錄生成完成');
  }

  /// 生成单日出勤记录
  Future<void> _generateDailyAttendance(DateTime date, ClassLocation location,
      List<StudentDetail> students) async {
    final records = students.map((student) {
      // 随机生成出勤状态，80%出席，15%请假，5%缺席
      final randomValue = _random.nextDouble();
      AttendanceStatus status;
      String leaveReason = "";

      if (randomValue < 0.8) {
        status = AttendanceStatus.attend;
      } else if (randomValue < 0.95) {
        status = AttendanceStatus.leave;
        leaveReason = _getRandomLeaveReason();
      } else {
        status = AttendanceStatus.absent;
      }

      return StudentDailyAttendanceRecord(
        student.id!,
        student.name,
        location,
        status,
        leaveReason: leaveReason,
      );
    }).toList();

    final attendanceInfo = DailyAttendanceInfo(date, location, records);
    await _dailyAttendanceRepo.save(attendanceInfo);
  }

  /// 生成单日表现记录
  Future<void> _generateDailyPerformance(DateTime date, ClassLocation location,
      List<StudentDetail> students) async {
    final records = students.map((student) {
      // 随机生成表现评级
      final performanceRating = _getRandomPerformanceRating();

      // 随机生成作业完成情况，70%完成
      final homeworkCompleted = _random.nextDouble() < 0.7;

      // 随机生成小帮手情况，20%是小帮手
      final isHelper = _random.nextDouble() < 0.2;

      // 随机生成备注，50%有备注
      final hasRemarks = _random.nextDouble() < 0.5;
      final remarks =
          hasRemarks ? _remarks[_random.nextInt(_remarks.length)] : "";

      return StudentDailyPerformanceRecord(
        student.id!,
        student.name,
        location,
        performanceRating,
        homeworkCompleted: homeworkCompleted,
        isHelper: isHelper,
        remarks: remarks,
        recordDate: date,
      );
    }).toList();

    final performanceInfo = DailyPerformanceInfo(date, location, records);
    await _dailyPerformanceRepo.save(performanceInfo);
  }

  /// 创建随机学生
  StudentDetail _createRandomStudent(ClassLocation location) {
    final lastName = _lastNames[_random.nextInt(_lastNames.length)];
    final firstName = _firstNames[_random.nextInt(_firstNames.length)];
    final name = '$lastName$firstName';

    final school = _schools[_random.nextInt(_schools.length)];

    // 随机生成性别
    final gender = _random.nextBool() ? '男' : '女';

    // 随机生成手机号码
    final phone = _generateRandomPhone();

    // 随机生成监护人信息
    final guardianName = '${lastName}父親';
    final guardianPhone = _generateRandomPhone();

    // 随机生成备注
    final description = _random.nextBool() ? '這是${name}的備註' : '';

    return StudentDetail(
      id: null,
      name: name,
      classLocation: location.name,
      gender: gender,
      phone: phone,
      birthday: DateTime(DateTime.now().year - 15, 01, 01),
      idNumber: "",
      school: school,
      email: "",
      economicStatus: EconomicStatus.normal,
      guardianName: guardianName,
      guardianIdNumber: "",
      guardianCompany: "",
      guardianPhone: guardianPhone,
      guardianEmail: "",
      emergencyContactName: "",
      emergencyContactIdNumber: "",
      emergencyContactCompany: "",
      emergencyContactPhone: "",
      emergencyContactEmail: "",
      hasSpecialDisease: false,
      specialDiseaseDescription: null,
      isSpecialStudent: false,
      specialStudentDescription: null,
      needsPickup: false,
      pickupRequirementDescription: null,
      familyStatus: FamilyStatus.bothParents,
      ethnicStatus: EthnicStatus.none,
      interest: "選項1",
      abilityEvaluation: "選項1",
      learningGoals: "選項1",
      resourcesAndScholarships: "選項1",
      talentClass: "",
      specialCourse: "",
      studentIntroduction: "",
      avatar: null,
      description: description,
    );
  }

  /// 生成随机手机号码
  String _generateRandomPhone() {
    return '09${_random.nextInt(10)}${_random.nextInt(10)}${_random.nextInt(10)}${_random.nextInt(10)}${_random.nextInt(10)}${_random.nextInt(10)}${_random.nextInt(10)}${_random.nextInt(10)}';
  }

  /// 获取随机城市
  String _getRandomCity() {
    final cities = ['台北', '新北', '桃園', '台中', '高雄', '台南', '新竹', '嘉義'];
    return cities[_random.nextInt(cities.length)];
  }

  /// 获取随机区域
  String _getRandomDistrict() {
    final districts = ['中正', '大安', '信義', '松山', '中山', '文山', '南港', '內湖'];
    return districts[_random.nextInt(districts.length)];
  }

  /// 获取随机请假原因
  String _getRandomLeaveReason() {
    final reasons = [
      '生病請假',
      '家庭因素',
      '看醫生',
      '外出旅行',
      '參加比賽',
      '個人事務',
    ];
    return reasons[_random.nextInt(reasons.length)];
  }

  /// 获取随机表现评级
  PerformanceRating _getRandomPerformanceRating() {
    // 优秀：30%，良好：40%，一般：20%，较差：10%
    final randomValue = _random.nextDouble();
    if (randomValue < 0.3) {
      return PerformanceRating.excellent;
    } else if (randomValue < 0.7) {
      return PerformanceRating.good;
    } else if (randomValue < 0.9) {
      return PerformanceRating.average;
    } else {
      return PerformanceRating.poor;
    }
  }
}
