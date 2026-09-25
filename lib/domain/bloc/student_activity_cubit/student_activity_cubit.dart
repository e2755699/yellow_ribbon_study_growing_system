import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_performance/student_daily_performance_info.dart';

class StudentActivityState {
  const StudentActivityState(
      {this.records = const [], this.loading = false, this.failed = false});
  final List<StudentDailyPerformanceRecord> records;
  final bool loading;
  final bool failed;
}

/// Read-only summary; opening a profile never creates daily records.
class StudentActivityCubit extends Cubit<StudentActivityState> {
  StudentActivityCubit(this.fetch) : super(const StudentActivityState());
  final Future<List<StudentDailyPerformanceRecord>> Function() fetch;

  Future<void> load() async {
    if (isClosed || state.loading) return;
    emit(const StudentActivityState(loading: true));
    try {
      final records = List<StudentDailyPerformanceRecord>.of(await fetch())
        ..sort((a, b) => b.recordDate.compareTo(a.recordDate));
      if (!isClosed) emit(StudentActivityState(records: records));
    } catch (_) {
      if (!isClosed) emit(const StudentActivityState(failed: true));
    }
  }
}
