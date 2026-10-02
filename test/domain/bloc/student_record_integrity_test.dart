// Regression invariants reproduced before implementation (all four were red).
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_performance_cubit/student_performance_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_daily_attendance_info_cubit/daily_attendance_info_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_daily_performance_cubit/daily_performance_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/performance_rating.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_attendance/student_daily_attendance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_performance/student_daily_performance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_attendance_repo.dart';
import 'daily_record_saving_test.dart'
    show MemoryAttendanceRepo, MemoryPerformanceRepo;
import 'student_detail_cubit_test.dart' show MemoryStudentsRepo;

class HistoryMemoryRepo extends MemoryPerformanceRepo {
  final writes = <String>[];
  bool reject = false;
  Completer<void>? gate;
  @override
  Future<void> saveRecord(StudentDailyPerformanceRecord row,
      {Map<String, dynamic>? expected}) async {
    if (reject) throw StateError('offline');
    writes.add(row.recordKey);
    await gate?.future;
  }
}

void main() {
  final location = ClassLocation.values.first;
  final firstDay = DateTime(2026, 9, 30);
  final secondDay = DateTime(2026, 10, 1);
  setUp(() => GetIt.I.registerSingleton<StudentsRepo>(MemoryStudentsRepo()));
  tearDown(() => GetIt.I.reset());

  StudentDailyPerformanceRecord record(DateTime day, String remark) =>
      StudentDailyPerformanceRecord(
          'synthetic-student', '合成學生', location, PerformanceRating.average,
          recordDate: day, remarks: remark);

  test('history only saves changed dates; failed save retains edit and error',
      () async {
    final repo = HistoryMemoryRepo();
    final cubit = StudentPerformanceCubit(
        StudentPerformanceState('synthetic-student',
            [record(firstDay, 'a'), record(secondDay, 'b')], Operate.view),
        repo);
    addTearDown(cubit.close);
    cubit.edit();
    cubit.state.records.last.remarksNotifier.value = 'edited';
    repo.reject = true;
    expect(await cubit.saveBeforeExit(), isFalse);
    expect(cubit.state.errorMessage, isNotNull);
    expect(cubit.hasUnsavedChanges(), isTrue);
    repo.reject = false;
    expect(await cubit.saveBeforeExit(), isTrue);
    expect(repo.writes, [cubit.state.records.last.recordKey]);
    expect(cubit.hasUnsavedChanges(), isFalse);
  });

  test(
      'save acknowledgement does not clear newer edits; duplicate tap shares save',
      () async {
    final repo = HistoryMemoryRepo()..gate = Completer<void>();
    final cubit = StudentPerformanceCubit(
        StudentPerformanceState(
            'synthetic-student', [record(firstDay, 'original')], Operate.view),
        repo);
    addTearDown(cubit.close);
    cubit.edit();
    cubit.state.records.single.remarksNotifier.value = 'submitted';
    final saving = cubit.saveBeforeExit();
    final duplicate = cubit.saveBeforeExit();
    cubit.state.records.single.remarksNotifier.value = 'newer';
    repo.gate!.complete();
    expect(await saving, isFalse);
    expect(await duplicate, isFalse);
    expect(repo.writes.length, 1);
    expect(cubit.state.records.single.remarksNotifier.value, 'newer');
    expect(cubit.hasUnsavedChanges(), isTrue);
    expect(cubit.state.isSaving, isFalse);
  });

  test('AUDIT: cancelling performance edit restores the original value', () {
    final row = record(firstDay, 'original');
    final cubit = StudentPerformanceCubit(
        StudentPerformanceState('synthetic-student', [row], Operate.view),
        MemoryPerformanceRepo());
    addTearDown(cubit.close);
    cubit.edit();
    row.remarksNotifier.value = 'unsaved';
    cubit.cancelEdit();
    expect(cubit.state.records.single.remarksNotifier.value, 'original');
  });

  test('AUDIT: changing the second day preserves the first day record', () {
    final first = record(firstDay, 'first');
    final second = record(secondDay, 'second');
    final cubit = StudentPerformanceCubit(
        StudentPerformanceState(
            'synthetic-student', [first, second], Operate.edit),
        MemoryPerformanceRepo());
    addTearDown(cubit.close);
    second.remarksNotifier.value = 'edited second';
    cubit.updateRecord(second);
    expect(cubit.state.records.map((r) => r.recordDate).toList(),
        [firstDay, secondDay]);
  });

  test('AUDIT: leaving unchanged attendance must not write a snapshot',
      () async {
    final repo = MemoryAttendanceRepo();
    GetIt.I.registerSingleton<DailyAttendanceRepo>(repo);
    final cubit = DailyAttendanceInfoCubit(StudentDailyAttendanceInfoState(
        DailyAttendanceInfo(firstDay, location, [])));
    addTearDown(cubit.close);
    await cubit.load(firstDay, location);
    expect(cubit.hasUnsavedChanges(), isFalse);
    expect(await cubit.saveBeforeExit(), isTrue);
    expect(repo.saved, isEmpty);
  });

  test('AUDIT: leaving unchanged performance must not write a snapshot',
      () async {
    final repo = MemoryPerformanceRepo();
    final cubit = DailyPerformanceCubit(
        StudentDailyPerformanceState(
            DailyPerformanceInfo(firstDay, location, [])),
        repo);
    addTearDown(cubit.close);
    await cubit.load(firstDay, location);
    expect(cubit.hasUnsavedChanges(), isFalse);
    expect(await cubit.saveBeforeExit(), isTrue);
    expect(repo.saved, isEmpty);
  });
}
