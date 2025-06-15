import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_attendance/student_daily_attendance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_attendance_repo.dart';

class DailyAttendanceInfoCubit
    extends Cubit<StudentDailyAttendanceInfoState> {
  final dailyAttendanceRepo = GetIt.I<DailyAttendanceRepo>();

  DailyAttendanceInfoCubit(super.initialState);

  Future<void> load(DateTime date, ClassLocation classLocation) async {
    emit(StudentDailyAttendanceInfoState(
        await dailyAttendanceRepo.load(date, classLocation)));
  }
  
  /// 獲取最早的出席記錄日期
  Future<DateTime> getEarliestDate() async {
    return await dailyAttendanceRepo.getEarliestDate();
  }

  void save() {
    dailyAttendanceRepo.save(state.dailyAttendanceInfo);
  }

  /// 用於離開頁面前的保存確認
  Future<bool> saveBeforeExit() async {
    try {
      await dailyAttendanceRepo.save(state.dailyAttendanceInfo);
      return true;
    } catch (e) {
      print('DailyAttendanceInfoCubit saveBeforeExit error: $e');
      return false;
    }
  }

  /// 檢查是否有未保存的變更（對於每日出席，總是可能有變更）
  bool hasUnsavedChanges() {
    return false; // 每日出席頁面不需要顯示保存確認對話框，因為是實時編輯
  }

  void delete() {
    dailyAttendanceRepo.delete(state.dailyAttendanceInfo.date,state.dailyAttendanceInfo.classLocation);
  }
}

class StudentDailyAttendanceInfoState {
  final DailyAttendanceInfo dailyAttendanceInfo;

  StudentDailyAttendanceInfoState(this.dailyAttendanceInfo);
}
