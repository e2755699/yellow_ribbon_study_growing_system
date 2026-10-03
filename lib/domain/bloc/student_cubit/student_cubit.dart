import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/yellow_ribbon_repo.dart';

class StudentsCubit extends Cubit<StudentsState> {
  StudentsCubit(super.initialState);

  Future<void> load() async {
    if (isClosed || state.isLoading) return;
    emit(StudentsState(state.students, isLoading: true));
    try {
      final students = await GetIt.I<StudentsRepo>().load();
      if (!isClosed) emit(StudentsState(students));
    } catch (error) {
      if (isClosed) return;
      final message =
          error is FirebaseException && error.code == 'permission-denied'
              ? '無法讀取學生資料，請確認帳號的存取權限。'
              : '學生資料載入失敗，請檢查網路連線後重試。';
      emit(StudentsState(state.students, errorMessage: message));
    }
  }

  Future<void> deleteStudent(String id) async {
    await GetIt.I<StudentsRepo>().delete(id);
    await YellowRibbonRepo().delete(id);
    await load();
  }
}

class StudentsState {
  final List<StudentDetail> students;
  final bool isLoading;
  final String? errorMessage;

  StudentsState(this.students, {this.isLoading = false, this.errorMessage});
}
