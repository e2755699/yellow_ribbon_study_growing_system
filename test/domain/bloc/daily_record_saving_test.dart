import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_daily_attendance_info_cubit/daily_attendance_info_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_daily_performance_cubit/daily_performance_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/performance_rating.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_attendance/student_daily_attendance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_performance/student_daily_performance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_attendance_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_performance_repo.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/daily_attendance_page/daily_attendance_page_widget.dart';

class MemoryAttendanceRepo implements DailyAttendanceRepo {
  bool failSave = false;
  int loads = 0;
  final saved = <Map<String, dynamic>>[];
  @override
  Future<DailyAttendanceInfo> load(
      DateTime date, ClassLocation location) async {
    loads++;
    return DailyAttendanceInfo(date, location, [
      StudentDailyAttendanceRecord('a', '學生', location, AttendanceStatus.absent)
    ]);
  }

  @override
  Future<void> save(DailyAttendanceInfo info) async {
    if (failSave) throw StateError('offline');
    saved.add(info.toFirebase());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryPerformanceRepo implements DailyPerformanceRepo {
  bool failSave = false;
  int loads = 0;
  final saved = <Map<String, dynamic>>[];
  @override
  Future<DailyPerformanceInfo> load(
      DateTime date, ClassLocation location) async {
    loads++;
    return DailyPerformanceInfo(date, location, [
      StudentDailyPerformanceRecord(
          'a', '學生', location, PerformanceRating.average)
    ]);
  }

  @override
  Future<void> save(DailyPerformanceInfo info) async {
    if (failSave) throw StateError('offline');
    saved.add(info.toFirebase());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final date = DateTime(2026, 9, 17);
  final location = ClassLocation.values.first;
  tearDown(() => GetIt.I.reset());

  test('attendance switch saves draft; failure preserves it and blocks load',
      () async {
    final repo = MemoryAttendanceRepo();
    GetIt.I.registerSingleton<DailyAttendanceRepo>(repo);
    final cubit = DailyAttendanceInfoCubit(StudentDailyAttendanceInfoState(
        DailyAttendanceInfo(date, location, [])));
    addTearDown(cubit.close);
    expect(await cubit.saveBeforeExit(), isTrue);
    expect(repo.saved, isEmpty);
    await cubit.load(date, location);
    expect(cubit.hasUnsavedChanges(), isFalse);
    cubit.state.dailyAttendanceInfo.records.single.attendanceStatusNotifier
        .value = AttendanceStatus.leave;
    cubit.state.dailyAttendanceInfo.records.single.leaveReasonNotifier.value =
        '測試原因';
    expect(cubit.hasUnsavedChanges(), isTrue);
    repo.failSave = true;
    await expectLater(cubit.load(date.add(const Duration(days: 1)), location),
        throwsStateError);
    expect(repo.loads, 1);
    expect(
        cubit
            .state.dailyAttendanceInfo.records.single.leaveReasonNotifier.value,
        '測試原因');
    repo.failSave = false;
    await cubit.load(date.add(const Duration(days: 1)), location);
    expect(repo.saved.single['date'], date);
    expect((repo.saved.single['records'] as List).single['status'], 'leave');
    expect(cubit.hasUnsavedChanges(), isFalse);
  });

  test('performance switch saves draft; failure preserves it and blocks load',
      () async {
    final repo = MemoryPerformanceRepo();
    final cubit = DailyPerformanceCubit(
        StudentDailyPerformanceState(DailyPerformanceInfo(date, location, [])),
        repo);
    addTearDown(cubit.close);
    expect(await cubit.saveBeforeExit(), isTrue);
    expect(repo.saved, isEmpty);
    await cubit.load(date, location);
    expect(cubit.hasUnsavedChanges(), isFalse);
    cubit.state.dailyPerformanceInfo.records.single.remarksNotifier.value =
        '待保存評語';
    expect(cubit.hasUnsavedChanges(), isTrue);
    repo.failSave = true;
    await expectLater(cubit.load(date.add(const Duration(days: 1)), location),
        throwsStateError);
    expect(repo.loads, 1);
    expect(
        cubit.state.dailyPerformanceInfo.records.single.remarksNotifier.value,
        '待保存評語');
    repo.failSave = false;
    await cubit.load(date.add(const Duration(days: 1)), location);
    expect(repo.saved.single['date'], date);
    expect((repo.saved.single['records'] as List).single['remarks'], '待保存評語');
    expect(cubit.hasUnsavedChanges(), isFalse);
  });
}
