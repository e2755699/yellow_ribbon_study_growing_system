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

  void delete() {
    dailyAttendanceRepo.delete(state.dailyAttendanceInfo.date,state.dailyAttendanceInfo.classLocation);
  }
}

class StudentDailyAttendanceInfoState {
  final DailyAttendanceInfo dailyAttendanceInfo;

  StudentDailyAttendanceInfoState(this.dailyAttendanceInfo);
}
