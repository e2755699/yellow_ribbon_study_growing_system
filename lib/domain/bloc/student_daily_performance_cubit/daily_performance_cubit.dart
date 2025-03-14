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

  DailyPerformanceCubit(super.initialState, this._repo);

  /// 加载指定日期和班级的每日表现数据
  Future<void> load(DateTime date, ClassLocation classLocation) async {
    final info = await _repo.load(date, classLocation);
    emit(StudentDailyPerformanceState(info));
  }

  /// 保存每日表现数据
  Future<void> save() async {
    await _repo.save(state.dailyPerformanceInfo);
  }

  /// 删除每日表现数据
  Future<void> delete() async {
    await _repo.delete(
        state.dailyPerformanceInfo.date, state.dailyPerformanceInfo.classLocation);
  }
} 