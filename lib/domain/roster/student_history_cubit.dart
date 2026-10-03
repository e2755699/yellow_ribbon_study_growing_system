import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'roster_models.dart';
import 'student_history_service.dart';

class StudentHistoryState {
  final BusinessDate month;
  final StudentHistory? history;
  final bool loading;
  final String? error;
  const StudentHistoryState(this.month,
      {this.history, this.loading = false, this.error});
}

class StudentHistoryCubit extends Cubit<StudentHistoryState> {
  final String studentId;
  final StudentHistoryService service;
  StreamSubscription<StudentHistory>? _subscription;
  int _generation = 0;
  StudentHistoryCubit(this.studentId, this.service, {BusinessDate? month})
      : super(StudentHistoryState(month ?? BusinessDate.today()));
  void start() => open(state.month);
  void open(BusinessDate month) {
    final generation = ++_generation;
    unawaited(_subscription?.cancel());
    emit(StudentHistoryState(month, loading: true));
    _subscription = service.watchMonth(studentId, month).listen((history) {
      if (!isClosed && generation == _generation) {
        emit(StudentHistoryState(month, history: history));
      }
    }, onError: (Object error) {
      if (!isClosed && generation == _generation) {
        emit(StudentHistoryState(month, error: '歷史資料尚未完整載入，請確認網路、權限或資料異常後重試'));
      }
    });
  }

  void moveMonth(int amount) => open(BusinessDate.fromCalendar(DateTime(
      state.month.calendar.year, state.month.calendar.month + amount)));
  @override
  Future<void> close() async {
    _generation++;
    await _subscription?.cancel();
    await super.close();
  }
}
