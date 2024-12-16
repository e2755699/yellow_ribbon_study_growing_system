import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';

class StudentsCubit extends Cubit<StudentsState> {
  StudentsCubit(super.initialState);

  Future<void> load() async {
    emit(StudentsState(await GetIt.I<StudentsRepo>().load()));
  }

  Future<void> deleteStudent(String id) async {
   await GetIt.I<StudentsRepo>().delete(id);
   load();
  }
}

class StudentsState {
  final List<StudentDetail> students;

  StudentsState(this.students);
}
