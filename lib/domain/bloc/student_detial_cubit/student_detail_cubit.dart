import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';

class StudentDetailCubit extends Cubit<StudentDetailState> {
  StudentDetailCubit(super.initialState);

  Future<void> create(StudentDetail studentDetail) async {
    tryCatchWrap(() async {
      await GetIt.I<StudentsRepo>().create(studentDetail);
      emit(StudentDetailState(studentDetail, Operate.view));
    }, errorMessage: "建立失敗");
  }

  void update(StudentDetail studentDetail) {
    tryCatchWrap(() async {
      await GetIt.I<StudentsRepo>().update(
          studentDetail.id.toString(), studentDetail);
    }, errorMessage: "更新失敗");
  }

  void save(StudentDetail student) {
    if (state.operate.isCreate) {
      create(student);
    }
    if (state.operate.isEdit) {
      update(student);
    }
    emit(StudentDetailState(student, Operate.view));
  }

  Future<void> tryCatchWrap(Future<void> Function() action,
      {required String errorMessage}) async {
    try {
      await action();
    } catch (e) {
      Fluttertoast.showToast(msg: errorMessage);
    }
  }

  void edit() {
    emit(StudentDetailState(state.detail, Operate.edit));
  }
}

class StudentDetailState {
  final StudentDetail detail;
  final Operate operate;

  StudentDetailState(this.detail, this.operate);

  bool get isView => operate.isView;
}
