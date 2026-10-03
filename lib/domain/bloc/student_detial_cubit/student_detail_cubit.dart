import '../../utils/subscription_failure.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';
import 'package:stream_transform/stream_transform.dart';
import '../../model/roster/roster_models.dart';
import '../../repo/roster_repository.dart';
import '../../model/roster/roster_command_failure.dart';
import '../../repo/yellow_ribbon_repo.dart';
import '../../model/yellow_ribbon/yellow_ribbon_count.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'student_detail_state.dart';

class StudentDetailCubit extends Cubit<StudentDetailState> {
  StudentDetailCubit(super.initialState, {this.roster, this.ribbons});
  final RosterRepository? roster;
  final YellowRibbonRepo? ribbons;
  YellowRibbonCount? ribbonCount;
  String? ribbonError;
  StreamSubscription<Map<String, YellowRibbonCount>>? _ribbonSubscription;
  List<ClassSite> sites = [];
  List<Enrollment> periods = [];
  RosterAccess? access;
  StudentDetail? _base, _createSubmission;
  int _profileGeneration = 0;
  StreamSubscription<StudentDetail?>? _studentSubscription;
  StreamSubscription<List<ClassSite>>? _siteSubscription;
  StreamSubscription<RosterAccess?>? _accessSubscription;
  StreamSubscription<List<Enrollment>>? _periodSubscription;
  bool get canManage => access?.enabled == true && access?.isManager == true;
  void start() {
    _siteSubscription ??= roster?.watchSites().listen((value) {
      sites = value;
      _refreshCatalog();
    }, onError: (Object error) {
      if (!isClosed)
        emit(StudentDetailError('據點載入失敗，請重新開啟',
            detail: state.detail, operate: state.operate));
    });
    _accessSubscription ??= roster?.watchAccess().listen((value) {
      access = value;
      _refreshCatalog();
    }, onError: (Object error) {
      if (clearsSubscriptionData(error)) access = null;
      _profileFailed(error, _profileGeneration);
    });
  }

  void _refreshCatalog() {
    if (isClosed || state is StudentDetailInitial) return;
    final old = state;
    if (old is StudentDetailError) {
      emit(StudentDetailError(old.message,
          detail: old.detail, operate: old.operate));
    } else {
      emit(StudentDetailLoaded(detail: state.detail, operate: state.operate));
    }
  }

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
    var creationConfirmed = false;
    try {
      var saved = detail;
      if (createNew) {
        final recovering = _createSubmission != null;
        _createSubmission ??= detail.copyWith(id: const Uuid().v4());
        String? id;
        try {
          id = await GetIt.I<StudentsRepo>().create(_createSubmission!);
        } catch (error) {
          // A definite first-attempt rejection permits a corrected submission.
          // Rejection of a retry cannot disprove an earlier unknown commit.
          if (!recovering &&
              error is RosterCommandFailure &&
              !error.outcomeUnknown &&
              error.code != 'already-exists') {
            _createSubmission = null;
          }
          rethrow;
        }
        if (id == null || id.isEmpty) throw StateError('學生建立失敗');
        creationConfirmed = true;
        saved = detail.copyWith(id: id);
        if (detail.locationId != _createSubmission!.locationId ||
            detail.enrollmentStartDate !=
                _createSubmission!.enrollmentStartDate) {
          _base = _createSubmission;
          if (!isClosed)
            emit(StudentDetailError('學生已建立；先前送出的入班資料已儲存，請到就讀異動核對日期與據點',
                detail: _createSubmission!, operate: Operate.view));
          return false;
        }
        // A lost response may have been followed by more edits. Finish the
        // original idempotent creation before patching those newer fields.
        if (!const DeepCollectionEquality().equals(
            StudentsRepo.profileValues(detail),
            StudentsRepo.profileValues(_createSubmission!))) {
          await GetIt.I<StudentsRepo>()
              .update(id, saved, expected: _createSubmission);
        }
      } else {
        final id = detail.id;
        if (id == null || id.isEmpty) throw StateError('缺少學生 ID');
        await GetIt.I<StudentsRepo>().update(id, detail, expected: _base);
      }
      final previous = createNew ? _createSubmission : _base;
      final oldValues = previous == null
          ? <String, dynamic>{}
          : StudentsRepo.profileValues(previous);
      final newValues = StudentsRepo.profileValues(saved);
      saved = saved.copyWith(persistedProfile: {
        ...?previous?.persistedProfile,
        if (previous?.persistedProfile == null) ...oldValues,
        for (final field in newValues.keys)
          if (createNew ||
              !const DeepCollectionEquality()
                  .equals(oldValues[field], newValues[field]))
            field: newValues[field]
      });
      _base = saved;
      if (!isClosed)
        emit(StudentDetailLoaded(detail: saved, operate: Operate.view));
      if (createNew && !isClosed) unawaited(loadStudentById(saved.id!));
      return true;
    } catch (_) {
      if (!isClosed)
        emit(StudentDetailError(
          createNew
              ? creationConfirmed
                  ? '學生已建立，但後續修改尚未完成；修改仍保留，請重試'
                  : _createSubmission != null
                      ? '建立結果尚未確認，請保留此頁並重試確認原請求，勿另建學生'
                      : '建立失敗，請修正資料或確認權限後重試'
              : '更新失敗，請重試',
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
    _base = studentDetail;
    emit(StudentDetailLoaded(detail: studentDetail, operate: operate));
  }

  void createStudentDetail({Operate operate = Operate.view}) {
    _createSubmission = null;
    emit(StudentDetailLoaded(
        detail: StudentDetail.empty()
            .copyWith(enrollmentStartDate: BusinessDate.today().value),
        operate: operate));
  }

  Future<void> loadStudentById(String studentId,
      {Operate operate = Operate.view}) async {
    final generation = ++_profileGeneration;
    try {
      await _ribbonSubscription?.cancel();
      _ribbonSubscription = ribbons?.watchCounts([studentId]).listen((counts) {
        ribbonCount = counts[studentId];
        ribbonError = null;
        _refreshCatalog();
      }, onError: (Object error) {
        if (clearsSubscriptionData(error)) ribbonCount = null;
        ribbonError = '黃絲帶數量載入失敗';
        _refreshCatalog();
      });
      await _periodSubscription?.cancel();
      _periodSubscription = roster?.watchAccess().switchMap((access) {
        if (access == null || access.locationIds.isEmpty)
          return Stream.value(<Enrollment>[]);
        final streams = [
          for (final id in access.locationIds)
            roster!.watchEnrollments(id, studentId: studentId)
        ];
        return streams.first
            .combineLatestAll(streams.skip(1))
            .map((snapshots) => snapshots.expand((s) => s.data).toList());
      }).listen((value) {
        periods = value;
        _refreshCatalog();
      }, onError: (Object error) {
        if (clearsSubscriptionData(error)) periods = [];
        if (!isClosed)
          emit(StudentDetailError('就讀期間載入失敗，請重新開啟',
              detail: state.detail, operate: state.operate));
      });
      await _studentSubscription?.cancel();
      final ready = Completer<void>();
      var first = true;
      _studentSubscription =
          GetIt.I<StudentsRepo>().watchById(studentId).listen((student) {
        if (isClosed || generation != _profileGeneration) {
          if (!ready.isCompleted) ready.complete();
          return;
        }
        if (student == null) {
          _base = null;
          emit(StudentDetailError('找不到學生資料',
              detail: StudentDetail.empty(), operate: Operate.view));
        } else if (first || state.isView) {
          _base = student;
          emit(StudentDetailLoaded(
              detail: student, operate: first ? operate : state.operate));
        }
        if (student != null) first = false;
        if (!ready.isCompleted) ready.complete();
      }, onError: (Object error) {
        _profileFailed(error, generation);
        if (!ready.isCompleted) ready.complete();
      }, onDone: () {
        if (generation == _profileGeneration) _studentSubscription = null;
        if (!ready.isCompleted) ready.complete();
      });
      await ready.future;
    } catch (error) {
      _profileFailed(error, generation);
    }
  }

  void _profileFailed(Object error, int generation) {
    if (isClosed || generation != _profileGeneration) return;
    if (clearsSubscriptionData(error)) {
      _base = null;
      ribbonCount = null;
      periods = [];
      emit(StudentDetailError('學生資料存取權限尚未確認',
          detail: StudentDetail.empty(), operate: Operate.view));
      return;
    }
    // The form owns unsaved text. Keeping edit mode keeps its widget and exit
    // guard alive; a transport error must not reset it to an empty view.
    emit(StudentDetailError('學生資料同步失敗，修改仍保留，請確認網路後重試',
        detail: state.detail, operate: state.operate));
  }

  void edit() {
    _base = state.detail;
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

  Future<bool> changeEnrollment(
      {required String mode,
      required BusinessDate date,
      String? locationId,
      String? enrollmentId,
      BusinessDate? endDate,
      String reason = ''}) async {
    if (!canManage || _saving || state.detail.id == null) return false;
    _saving = true;
    try {
      if (mode == 'correct') {
        await roster!.command({
          'action': 'correctEnrollment',
          'operationId': const Uuid().v4(),
          'studentId': state.detail.id,
          'enrollmentId': enrollmentId,
          'startDate': date.value,
          'endDateExclusive': endDate!.value,
          'reason': reason,
          'expectedRevision': state.detail.enrollmentRevision
        });
      } else {
        await GetIt.I<StudentsRepo>().changeEnrollment(state.detail,
            mode: mode, date: date, locationId: locationId);
      }
      return true;
    } catch (_) {
      if (!isClosed)
        emit(StudentDetailError('就讀異動未完成，請確認日期、權限或其他裝置的異動',
            detail: state.detail, operate: state.operate));
      return false;
    } finally {
      _saving = false;
    }
  }

  @override
  Future<void> close() async {
    await _studentSubscription?.cancel();
    await _siteSubscription?.cancel();
    await _periodSubscription?.cancel();
    await _ribbonSubscription?.cancel();
    await _accessSubscription?.cancel();
    await super.close();
  }
}
