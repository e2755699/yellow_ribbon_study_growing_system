import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_performance/student_daily_performance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_performance_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';

class StudentPerformanceState {
  final String studentId;
  final List<StudentDailyPerformanceRecord> records;
  final Operate operate;
  final List<StudentDailyPerformanceRecord> originalRecords; // 保存原始记录，用于取消编辑
  final StudentDetail? studentDetail; // 学生详细信息
  final String? errorMessage;
  final bool isSaving;

  StudentPerformanceState(this.studentId, this.records, this.operate,
      {List<StudentDailyPerformanceRecord>? originalRecords,
      this.studentDetail,
      this.errorMessage,
      this.isSaving = false})
      : originalRecords = originalRecords ??
            records.map((record) => record.detachedCopy()).toList();

  StudentPerformanceState copyWith({
    String? studentId,
    List<StudentDailyPerformanceRecord>? records,
    Operate? operate,
    List<StudentDailyPerformanceRecord>? originalRecords,
    StudentDetail? studentDetail,
    String? errorMessage,
    bool? isSaving,
  }) {
    return StudentPerformanceState(
      studentId ?? this.studentId,
      records ?? this.records,
      operate ?? this.operate,
      originalRecords: originalRecords ?? this.originalRecords,
      studentDetail: studentDetail ?? this.studentDetail,
      errorMessage: errorMessage,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

class StudentPerformanceCubit extends Cubit<StudentPerformanceState> {
  final DailyPerformanceRepo _dailyPerformanceRepo;
  final StudentsRepo _studentsRepo;
  Future<bool>? _saveInFlight;

  StudentPerformanceCubit(super.initialState, this._dailyPerformanceRepo)
      : _studentsRepo = GetIt.I<StudentsRepo>();

  Future<void> load(String studentId) async {
    await tryCatchWrap(() async {
      // 加载学生表现记录
      final records = await _dailyPerformanceRepo.loadByStudentId(studentId);

      // 加载学生详细信息
      await _studentsRepo.load(); // 确保学生数据已加载
      final studentDetail = _studentsRepo.getStudentDetail(studentId);

      emit(state.copyWith(
        studentId: studentId,
        records: records,
        operate: Operate.view,
        originalRecords:
            records.map((record) => record.detachedCopy()).toList(),
        studentDetail: studentDetail,
      ));
    });
  }

  // 更新单个记录（编辑模式下）
  void updateRecord(StudentDailyPerformanceRecord record) {
    final updatedRecords =
        List<StudentDailyPerformanceRecord>.from(state.records);
    final index =
        updatedRecords.indexWhere((r) => r.recordKey == record.recordKey);
    if (index != -1) {
      updatedRecords[index] = record;
      emit(state.copyWith(records: updatedRecords));
    }
  }

  // 进入编辑模式
  void edit() {
    emit(state.copyWith(
      operate: Operate.edit,
      originalRecords:
          state.records.map((record) => record.detachedCopy()).toList(),
    ));
  }

  // 保存所有记录
  Future<bool> save() => saveBeforeExit();

  /// 用於離開頁面前的保存確認
  Future<bool> saveBeforeExit() =>
      _saveInFlight ??= _performSave().whenComplete(() => _saveInFlight = null);

  Future<bool> _performSave() async {
    if (isClosed) return false;
    emit(state.copyWith(isSaving: true));
    try {
      // 只有在編輯模式下才保存
      if (hasUnsavedChanges()) {
        final submitted = state.records
            .where(_isDirty)
            .map((record) => record.detachedCopy())
            .toList();
        for (final record in submitted) {
          await _dailyPerformanceRepo.saveRecord(record,
              expected: _baseFor(record));
          if (isClosed) return false;
          final originals = {
            for (final row in state.originalRecords) row.recordKey: row,
            record.recordKey: record.detachedCopy(),
          };
          emit(state.copyWith(originalRecords: originals.values.toList()));
        }
      }
      if (isClosed) return false;
      if (hasUnsavedChanges()) return false;
      emit(state.copyWith(operate: Operate.view));
      return true;
    } catch (e) {
      if (!isClosed)
        emit(state.copyWith(errorMessage: '儲存失敗或資料衝突，尚未完成的修改已保留。'));
      return false;
    } finally {
      if (!isClosed)
        emit(state.copyWith(isSaving: false, errorMessage: state.errorMessage));
    }
  }

  /// 檢查是否有未保存的變更
  bool hasUnsavedChanges() {
    return state.records.any(_isDirty);
  }

  bool _isDirty(StudentDailyPerformanceRecord record) {
    final base =
        state.originalRecords.where((row) => row.recordKey == record.recordKey);
    return base.isEmpty ||
        jsonEncode(base.first.toFirebase()) != jsonEncode(record.toFirebase());
  }

  Map<String, dynamic>? _baseFor(StudentDailyPerformanceRecord record) {
    final rows =
        state.originalRecords.where((row) => row.recordKey == record.recordKey);
    return rows.isEmpty ? null : rows.first.toFirebase();
  }

  // 取消编辑，恢复原始记录
  void cancelEdit() {
    if (state.isSaving) return;
    emit(state.copyWith(
      records:
          state.originalRecords.map((record) => record.detachedCopy()).toList(),
      operate: Operate.view,
    ));
  }

  Future<void> saveRecord(StudentDailyPerformanceRecord record) async {
    await tryCatchWrap(() async {
      await _dailyPerformanceRepo.saveRecord(record,
          expected: _baseFor(record));
      // 重新加载数据
      await load(state.studentId);
    });
  }

  Future<void> tryCatchWrap(Future<void> Function() callback) async {
    try {
      await callback();
    } catch (e) {
      // 在实际应用中，应该处理错误
      print('Error in StudentPerformanceCubit: $e');
    }
  }
}
