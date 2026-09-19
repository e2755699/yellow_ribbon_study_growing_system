import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'student_detail_state.dart';

class StudentDetailCubit extends Cubit<StudentDetailState> {
  StudentDetailCubit(super.initialState);
  bool _saving = false;
  bool get isSaving => _saving;

  Future<bool> create(StudentDetail studentDetail) =>
      _save(studentDetail, createNew: true);
  Future<bool> update(StudentDetail studentDetail) =>
      _save(studentDetail, createNew: false);

  Future<bool> _save(StudentDetail detail, {required bool createNew}) async {
    if (_saving) return false;
    _saving = true;
    final operate = state.operate;
    try {
      var saved = detail;
      if (createNew) {
        final id = await GetIt.I<StudentsRepo>().create(detail);
        if (id == null || id.isEmpty) throw StateError('學生建立失敗');
        saved = detail.copyWith(id: id);
      } else {
        final id = detail.id;
        if (id == null || id.isEmpty) throw StateError('缺少學生 ID');
        await GetIt.I<StudentsRepo>().update(id, detail);
      }
      if (!isClosed)
        emit(StudentDetailLoaded(detail: saved, operate: Operate.view));
      return true;
    } catch (_) {
      if (!isClosed)
        emit(StudentDetailError(
          createNew ? '建立失敗，請重試' : '更新失敗，請重試',
          detail: detail,
          operate: operate,
        ));
      return false;
    } finally {
      _saving = false;
    }
  }

  void loadStudentDetail(StudentDetail studentDetail,
      {Operate operate = Operate.view}) {
    emit(StudentDetailLoaded(detail: studentDetail, operate: operate));
  }

  void createStudentDetail({Operate operate = Operate.view}) {
    emit(StudentDetailLoaded(detail: StudentDetail.empty(), operate: operate));
  }

  Future<void> loadStudentById(String studentId,
      {Operate operate = Operate.view}) async {
    try {
      final student = await GetIt.I<StudentsRepo>().getById(studentId);
      if (isClosed) return;
      if (student != null) {
        emit(StudentDetailLoaded(detail: student, operate: operate));
      } else {
        emit(StudentDetailError('找不到學生資料',
            detail: state.detail, operate: operate));
      }
    } catch (_) {
      if (!isClosed)
        emit(StudentDetailError('載入學生資料失敗',
            detail: state.detail, operate: operate));
    }
  }

  void edit() {
    emit(StudentDetailLoaded(detail: state.detail, operate: Operate.edit));
  }

  Future<bool> save(StudentDetail detail) {
    if (state.isCreate) return create(detail);
    if (state.isEdit) return update(detail);
    return Future.value(false);
  }

  bool hasUnsavedChanges() => state.isEdit || state.isCreate;

  // File operations persist only the file field through StudentAttachmentService.
  // Synchronizing the displayed record must not save or discard a form draft.
  void syncProfileFile(String? fileName) {
    emit(StudentDetailLoaded(
        detail: state.detail.copyWith(profileFileName: fileName),
        operate: state.operate));
  }

  void syncAvatar(String? fileName) {
    emit(StudentDetailLoaded(
        detail: state.detail.copyWith(avatar: fileName),
        operate: state.operate));
  }
}
