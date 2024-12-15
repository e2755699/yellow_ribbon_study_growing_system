import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/daily_attendance_page/daily_attendance_page_widget.dart';
import 'package:yellow_ribbon_study_growing_system/model/daily_attendance/student_daily_attendance_info.dart';

class StudentDailyAttendanceInfoCubit extends Cubit<StudentDailyAttendanceInfoState> {
  late List<StudentDailyAttendanceInfo> students;
  StudentDailyAttendanceInfoCubit(super.initialState);

  void load() {
    var _students = [
      StudentDailyAttendanceInfo(1, "劉兆凌", ClassLocation.TainanYongkang),
      StudentDailyAttendanceInfo(2, "莊研安", ClassLocation.TainanYongkang),
      StudentDailyAttendanceInfo(3, "蔡文鐘", ClassLocation.TainanNaiman),
      StudentDailyAttendanceInfo(4, "蔡靜瑩", ClassLocation.TainanNaiman),
      StudentDailyAttendanceInfo(5, "黃彭漢", ClassLocation.TainanNorthDistrict),
    ];
    students = _students;
    emit(StudentDailyAttendanceInfoState(_students));
  }

  void filter(ClassLocation classLocation) {
    emit(StudentDailyAttendanceInfoState(students
        .where((student) => student.classLocation == classLocation)
        .toList()));
  }
}

class StudentDailyAttendanceInfoState {
  final List<StudentDailyAttendanceInfo> students;

  StudentDailyAttendanceInfoState(this.students);
}
