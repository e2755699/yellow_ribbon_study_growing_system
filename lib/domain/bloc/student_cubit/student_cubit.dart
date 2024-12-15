import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';

class StudentsCubit extends Cubit<StudentsState> {
  StudentsCubit(super.initialState);

  void load() {
    var students = GetIt.I<StudentsRepo>().load();
    emit(StudentsState(students));
  }

  StudentDetail getStudentDetail(int? sid) {
    return state.getStudent(sid);
  }
}

class StudentsState {
  final List<StudentDetail> students;

  StudentsState(this.students);

  StudentDetail getStudent(int? sid) {
    return students.where((student) => student.id == sid).firstOrNull ?? StudentDetail.empty();
  }
}
