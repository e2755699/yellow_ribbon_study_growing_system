import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_performance/student_daily_performance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_performance_repo.dart';

class StudentDailyPerformanceState {
  final DailyPerformanceInfo dailyPerformanceInfo;

  StudentDailyPerformanceState(this.dailyPerformanceInfo);
}

class DailyPerformanceCubit extends Cubit<StudentDailyPerformanceState> {
  final DailyPerformanceRepo _repo;
  String? _savedSnapshot;
  String get _snapshot => jsonEncode(state.dailyPerformanceInfo.toFirebase(),
      toEncodable: (value) => (value as DateTime).toIso8601String());

  DailyPerformanceCubit(super.initialState, this._repo);

  /// 加载指定日期和班级的每日表现数据
  Future<void> load(DateTime date, ClassLocation classLocation) async {
    if (hasUnsavedChanges() && !await saveBeforeExit()) {
      throw StateError('目前的表現資料尚未儲存');
    }
    final info = await _repo.load(date, classLocation);
    if (!isClosed) {
      emit(StudentDailyPerformanceState(info));
      _savedSnapshot = _snapshot;
    }
  }

  /// 保存每日表现数据
  Future<void> save() async {
    if (_savedSnapshot == null && state.dailyPerformanceInfo.records.isEmpty)
      return;
    final snapshot = _snapshot;
    await _repo.save(state.dailyPerformanceInfo);
    _savedSnapshot = snapshot;
  }

  /// 用於離開頁面前的保存確認
  Future<bool> saveBeforeExit() async {
    try {
      await save();
      return true;
    } catch (e) {
      print('DailyPerformanceCubit saveBeforeExit error: $e');
      return false;
    }
  }

  /// 檢查是否有未保存的變更（對於每日表現，總是可能有變更）
  bool hasUnsavedChanges() {
    return _savedSnapshot == null
        ? state.dailyPerformanceInfo.records.isNotEmpty
        : _snapshot != _savedSnapshot;
  }

  /// 删除每日表现数据
  Future<void> delete() async {
    await _repo.delete(state.dailyPerformanceInfo.date,
        state.dailyPerformanceInfo.classLocation);
  }
}
