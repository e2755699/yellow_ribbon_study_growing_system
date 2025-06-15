import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_state.dart';

class StudentDetailCubit extends Cubit<StudentDetailState> {
  StudentDetailCubit(super.initialState);

  Future<void> create(StudentDetail studentDetail) async {
    tryCatchWrap(() async {
      await GetIt.I<StudentsRepo>().create(studentDetail);
      emit(StudentDetailLoaded(
        detail: studentDetail,
        operate: Operate.view,
      ));
    }, errorMessage: "建立失敗");
  }

  void update(StudentDetail studentDetail) {
    tryCatchWrap(() async {
      await GetIt.I<StudentsRepo>().update(studentDetail.id!, studentDetail);
      emit(StudentDetailLoaded(
        detail: studentDetail,
        operate: Operate.view,
      ));
    }, errorMessage: "更新失敗");
  }

  void loadStudentDetail(StudentDetail studentDetail, {Operate operate = Operate.view}) {
    emit(StudentDetailLoaded(
      detail: studentDetail,
      operate: operate,
    ));
  }

  Future<void> loadStudentById(String studentId, {Operate operate = Operate.view}) async {
    await tryCatchWrap(() async {
      final student = await GetIt.I<StudentsRepo>().getById(studentId);
      if (student != null) {
        emit(StudentDetailLoaded(
          detail: student,
          operate: operate,
        ));
      } else {
        // 如果找不到學生，發出錯誤狀態或保持初始狀態
        emit(StudentDetailError("找不到學生資料", detail: state.detail));
      }
    }, errorMessage: "載入學生資料失敗");
  }

  void edit() {
    if (state is StudentDetailLoaded) {
      final currentState = state as StudentDetailLoaded;
      emit(currentState.copyWith(operate: Operate.edit));
    }
  }

  void save(StudentDetail studentDetail) {
    if (state.operate == Operate.create) {
      create(studentDetail);
    } else if (state.operate == Operate.edit) {
      update(studentDetail);
    }
  }

  void updateAvatar(String studentId, String avatarUrl) {
    if (state is StudentDetailLoaded) {
      final currentState = state as StudentDetailLoaded;
      final updatedStudent = currentState.detail.copyWith(avatar: avatarUrl);
      update(updatedStudent);
    }
  }

  Future<void> tryCatchWrap(Future<void> Function() action,
      {required String errorMessage}) async {
    try {
      await action();
    } catch (e) {
      print('StudentDetailCubit error: $e');
      Fluttertoast.showToast(msg: errorMessage);
      // 發出錯誤狀態
      if (state is StudentDetailLoaded) {
        final currentState = state as StudentDetailLoaded;
        emit(StudentDetailError(errorMessage, detail: currentState.detail));
      } else {
        emit(StudentDetailError(errorMessage, detail: StudentDetail.empty()));
      }
    }
  }
}

