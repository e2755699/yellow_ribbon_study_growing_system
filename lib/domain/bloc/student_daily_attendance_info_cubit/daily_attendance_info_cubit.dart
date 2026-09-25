import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_attendance/student_daily_attendance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_attendance_repo.dart';

class DailyAttendanceInfoCubit extends Cubit<StudentDailyAttendanceInfoState> {
  final dailyAttendanceRepo = GetIt.I<DailyAttendanceRepo>();
  String? _savedSnapshot;
  String get _snapshot => jsonEncode(state.dailyAttendanceInfo.toFirebase(),
      toEncodable: (value) => (value as DateTime).toIso8601String());

  DailyAttendanceInfoCubit(super.initialState);

  Future<void> load(DateTime date, ClassLocation classLocation) async {
    if (hasUnsavedChanges() && !await saveBeforeExit()) {
      throw StateError('目前的出席資料尚未儲存');
    }
    final info = await dailyAttendanceRepo.load(date, classLocation);
    if (!isClosed) {
      emit(StudentDailyAttendanceInfoState(info));
      _savedSnapshot = _snapshot;
    }
  }

  /// 獲取最早的出席記錄日期
  Future<DateTime> getEarliestDate() async {
    return await dailyAttendanceRepo.getEarliestDate();
  }

  Future<void> save() async {
    if (_savedSnapshot == null && state.dailyAttendanceInfo.records.isEmpty)
      return;
    final snapshot = _snapshot;
    await dailyAttendanceRepo.save(state.dailyAttendanceInfo);
    _savedSnapshot = snapshot;
  }

  /// 用於離開頁面前的保存確認
  Future<bool> saveBeforeExit() async {
    try {
      await save();
      return true;
    } catch (e) {
      print('DailyAttendanceInfoCubit saveBeforeExit error: $e');
      return false;
    }
  }

  /// 檢查是否有未保存的變更（對於每日出席，總是可能有變更）
  bool hasUnsavedChanges() {
    return _savedSnapshot == null
        ? state.dailyAttendanceInfo.records.isNotEmpty
        : _snapshot != _savedSnapshot;
  }

  void delete() {
    dailyAttendanceRepo.delete(state.dailyAttendanceInfo.date,
        state.dailyAttendanceInfo.classLocation);
  }
}

class StudentDailyAttendanceInfoState {
  final DailyAttendanceInfo dailyAttendanceInfo;

  StudentDailyAttendanceInfoState(this.dailyAttendanceInfo);
}
