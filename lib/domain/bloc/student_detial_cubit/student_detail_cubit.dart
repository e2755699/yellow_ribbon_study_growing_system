import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_state.dart'
    as detail_state;

class StudentDetailCubit extends Cubit<detail_state.StudentDetailState>
    implements StateStreamable<detail_state.StudentDetailState> {
  StudentDetailCubit(super.initialState);

  Future<void> create(StudentDetail studentDetail) async {
    tryCatchWrap(() async {
      await GetIt.I<StudentsRepo>().create(studentDetail);
      emit(detail_state.StudentDetailLoaded(
        studentDetail: studentDetail,
        operate: detail_state.Operate.view,
      ));
    }, errorMessage: "建立失敗");
  }

  void update(StudentDetail studentDetail) {
    tryCatchWrap(() async {
      await GetIt.I<StudentsRepo>().update(studentDetail.id!, studentDetail);
      emit(detail_state.StudentDetailLoaded(
        studentDetail: studentDetail,
        operate: detail_state.Operate.view,
      ));
    }, errorMessage: "更新失敗");
  }

  void loadStudentDetail(StudentDetail studentDetail) {
    emit(detail_state.StudentDetailLoaded(
      studentDetail: studentDetail,
      operate: detail_state.Operate.view,
    ));
  }

  void edit() {
    if (state is detail_state.StudentDetailLoaded) {
      final currentState = state as detail_state.StudentDetailLoaded;
      emit(detail_state.StudentDetailLoaded(
        studentDetail: currentState.studentDetail,
        operate: detail_state.Operate.edit,
      ));
    }
  }

  void save(StudentDetail studentDetail) {
    if (state is detail_state.StudentDetailLoaded) {
      final currentState = state as detail_state.StudentDetailLoaded;
      if (currentState.operate == detail_state.Operate.create) {
        create(studentDetail);
      } else if (currentState.operate == detail_state.Operate.edit) {
        update(studentDetail);
      }
    }
  }

  void updateAvatar(String studentId, String avatarUrl) {
    if (state is detail_state.StudentDetailLoaded) {
      final currentState = state as detail_state.StudentDetailLoaded;
      final updatedStudent =
          currentState.studentDetail.copyWith(avatar: avatarUrl);
      update(updatedStudent);
    }
  }

  Future<void> tryCatchWrap(Future<void> Function() action,
      {required String errorMessage}) async {
    try {
      await action();
    } catch (e) {
      Fluttertoast.showToast(msg: errorMessage);
    }
  }
}

class StudentDetailState {
  final StudentDetail detail;
  final Operate operate;

  StudentDetailState(this.detail, this.operate);

  bool get isView => operate.isView;
}
