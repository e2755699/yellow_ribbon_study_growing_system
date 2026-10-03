import '../../utils/subscription_failure.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import '../../roster/roster_models.dart';
import '../../service/student_directory_policy.dart';
import '../../repo/yellow_ribbon_repo.dart';
import '../../model/yellow_ribbon/yellow_ribbon_count.dart';
import '../../roster/roster_repository.dart';

class StudentsCubit extends Cubit<StudentsState> {
  StudentsCubit(super.initialState, {this.roster, this.ribbons});
  final RosterRepository? roster;
  final YellowRibbonRepo? ribbons;
  StreamSubscription<List<StudentDetail>>? _subscription;
  StreamSubscription<List<ClassSite>>? _sites;
  StreamSubscription<RosterAccess?>? _access;
  int _countGeneration = 0;
  StreamSubscription<Map<String, YellowRibbonCount>>? _counts;
  String? _countKey;
  int _generation = 0;
  Completer<void>? _ready;

  Future<void> load() async {
    if (isClosed || state.isLoading) return;
    final generation = ++_generation;
    emit(state.copy(isLoading: true, clearError: true));
    _access ??= roster?.watchAccess().listen((access) {
      if (isClosed) return;
      if (access == null) {
        emit(state.copy(students: [], counts: {}, sites: [], canManage: false));
      }
      if (!isClosed)
        emit(state.copy(
            canManage: access?.isManager == true && access?.enabled == true));
    }, onError: (Object error) {
      if (!isClosed)
        emit(state.copy(
            students: clearsSubscriptionData(error) ? [] : null,
            counts: clearsSubscriptionData(error) ? {} : null,
            canManage: clearsSubscriptionData(error) ? false : null,
            errorMessage: '權限同步失敗，請重試；目前資料可能不是最新'));
    });
    try {
      _sites ??= roster?.watchSites().listen((sites) {
        if (!isClosed)
          emit(state.copy(
              sites: sites,
              locationId:
                  sites.any((s) => s.id == state.locationId) ? null : ''));
      }, onError: (Object error) {
        if (!isClosed)
          emit(state.copy(
              sites: clearsSubscriptionData(error) ? [] : null,
              isLoading: false,
              errorMessage: '據點載入失敗，請重試'));
      });
      unawaited(_subscription?.cancel());
      final ready = Completer<void>();
      _ready = ready;
      _subscription = GetIt.I<StudentsRepo>().watch().listen((students) {
        if (isClosed || generation != _generation) {
          if (!ready.isCompleted) ready.complete();
          return;
        }
        if (!isClosed)
          emit(state.copy(
              students: students, isLoading: false, clearError: true));
        final ids = students.map((s) => s.id).whereType<String>().toList()
          ..sort();
        if (_countKey != ids.join('|')) {
          _countKey = ids.join('|');
          unawaited(_counts?.cancel());
          final countGeneration = ++_countGeneration;
          emit(state.copy(counts: {}, clearRibbonError: true));
          _counts = ribbons?.watchCounts(ids).listen((counts) {
            if (!isClosed && countGeneration == _countGeneration)
              emit(state.copy(counts: counts, clearRibbonError: true));
          }, onError: (Object error) {
            if (!isClosed && countGeneration == _countGeneration)
              emit(state.copy(
                  counts: clearsSubscriptionData(error) ? {} : null,
                  ribbonError: '黃絲帶數量同步失敗，目前數量可能不是最新'));
          });
        }
        if (!ready.isCompleted) ready.complete();
      }, onError: (Object error) {
        if (isClosed || generation != _generation) {
          if (!ready.isCompleted) ready.complete();
          return;
        }
        if (!isClosed)
          emit(state.copy(
              students: clearsSubscriptionData(error) ? [] : null,
              counts: clearsSubscriptionData(error) ? {} : null,
              isLoading: false,
              errorMessage: clearsSubscriptionData(error)
                  ? '無法讀取學生資料，請確認帳號的存取權限。'
                  : '學生資料載入失敗，請檢查網路連線後重試。'));
        if (!ready.isCompleted) ready.complete();
      });
      await ready.future;
    } catch (error) {
      if (isClosed) return;
      final message = clearsSubscriptionData(error)
          ? '無法讀取學生資料，請確認帳號的存取權限。'
          : '學生資料載入失敗，請檢查網路連線後重試。';
      emit(state.copy(
          students: clearsSubscriptionData(error) ? [] : null,
          counts: clearsSubscriptionData(error) ? {} : null,
          isLoading: false,
          errorMessage: message));
    }
  }

  Future<void> deleteStudent(String id) async {
    await GetIt.I<StudentsRepo>().delete(id);
  }

  void search(String value) => emit(state.copy(search: value));
  void selectLocation(String value) => emit(state.copy(locationId: value));
  void includeArchived(bool value) => emit(state.copy(includeArchived: value));
  @override
  Future<void> close() async {
    _generation++;
    _countGeneration++;
    if (_ready?.isCompleted == false) _ready!.complete();
    await _subscription?.cancel();
    await _sites?.cancel();
    await _counts?.cancel();
    await _access?.cancel();
    await super.close();
  }
}

class StudentsState {
  final List<StudentDetail> students;
  final bool isLoading;
  final String? errorMessage;
  final String search, locationId;
  final bool includeArchived, canManage;
  final List<ClassSite> sites;
  final Map<String, YellowRibbonCount> counts;
  final String? ribbonError;

  StudentsState(this.students,
      {this.isLoading = false,
      this.errorMessage,
      this.search = '',
      this.locationId = '',
      this.includeArchived = false,
      this.sites = const [],
      this.counts = const {},
      this.ribbonError,
      this.canManage = false});
  List<StudentDetail> get visibleStudents =>
      StudentDirectoryPolicy.filter(students,
          locationId: locationId,
          search: search,
          includeArchived: includeArchived);
  List<StudentDetail> get inLocation => StudentDirectoryPolicy.filter(students,
      locationId: locationId, includeArchived: includeArchived);
  StudentsState copy(
          {List<StudentDetail>? students,
          bool? isLoading,
          bool clearError = false,
          bool clearRibbonError = false,
          bool? canManage,
          String? errorMessage,
          String? search,
          String? locationId,
          bool? includeArchived,
          List<ClassSite>? sites,
          Map<String, YellowRibbonCount>? counts,
          String? ribbonError}) =>
      StudentsState(List.unmodifiable(students ?? this.students),
          isLoading: isLoading ?? this.isLoading,
          errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
          search: search ?? this.search,
          locationId: locationId ?? this.locationId,
          includeArchived: includeArchived ?? this.includeArchived,
          sites: sites ?? this.sites,
          counts: counts ?? this.counts,
          ribbonError:
              clearRibbonError ? null : ribbonError ?? this.ribbonError,
          canManage: canManage ?? this.canManage);
}
