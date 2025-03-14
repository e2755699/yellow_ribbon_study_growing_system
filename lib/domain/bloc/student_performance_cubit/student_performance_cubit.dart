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

  StudentPerformanceState(
    this.studentId, 
    this.records, 
    this.operate, 
    {List<StudentDailyPerformanceRecord>? originalRecords, 
    this.studentDetail}
  ) : originalRecords = originalRecords ?? List.from(records);

  StudentPerformanceState copyWith({
    String? studentId,
    List<StudentDailyPerformanceRecord>? records,
    Operate? operate,
    List<StudentDailyPerformanceRecord>? originalRecords,
    StudentDetail? studentDetail,
  }) {
    return StudentPerformanceState(
      studentId ?? this.studentId,
      records ?? this.records,
      operate ?? this.operate,
      originalRecords: originalRecords ?? this.originalRecords,
      studentDetail: studentDetail ?? this.studentDetail,
    );
  }
}

class StudentPerformanceCubit extends Cubit<StudentPerformanceState> {
  final DailyPerformanceRepo _dailyPerformanceRepo;
  final StudentsRepo _studentsRepo;

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
        originalRecords: List.from(records),
        studentDetail: studentDetail,
      ));
    });
  }

  // 更新单个记录（编辑模式下）
  void updateRecord(StudentDailyPerformanceRecord record) {
    final updatedRecords = List<StudentDailyPerformanceRecord>.from(state.records);
    final index = updatedRecords.indexWhere((r) => r.sid == record.sid);
    if (index != -1) {
      updatedRecords[index] = record;
      emit(state.copyWith(records: updatedRecords));
    }
  }

  // 进入编辑模式
  void edit() {
    emit(state.copyWith(
      operate: Operate.edit,
      originalRecords: List.from(state.records),
    ));
  }

  // 保存所有记录
  Future<void> save() async {
    await tryCatchWrap(() async {
      // 保存所有记录
      for (var record in state.records) {
        await _dailyPerformanceRepo.saveRecord(record);
      }
      
      // 重新加载数据并返回查看模式
      await load(state.studentId);
    });
  }

  // 取消编辑，恢复原始记录
  void cancelEdit() {
    emit(state.copyWith(
      records: List.from(state.originalRecords),
      operate: Operate.view,
    ));
  }

  Future<void> saveRecord(StudentDailyPerformanceRecord record) async {
    await tryCatchWrap(() async {
      await _dailyPerformanceRepo.saveRecord(record);
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