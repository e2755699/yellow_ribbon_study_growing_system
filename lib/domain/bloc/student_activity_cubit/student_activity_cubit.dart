import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../roster/roster_models.dart';

class StudentActivityState {
  const StudentActivityState(
      {this.records = const [], this.loading = false, this.failed = false});
  final List<DailyRecord> records;
  final bool loading, failed;
}

class StudentActivityCubit extends Cubit<StudentActivityState> {
  StudentActivityCubit(Future<List<DailyRecord>> Function() fetch)
      : watch = (() => Stream.fromFuture(fetch())),
        super(const StudentActivityState());
  StudentActivityCubit.watching(this.watch)
      : super(const StudentActivityState());
  final Stream<List<DailyRecord>> Function() watch;
  StreamSubscription<List<DailyRecord>>? _subscription;
  void load() {
    if (isClosed || state.loading) return;
    unawaited(_subscription?.cancel());
    emit(const StudentActivityState(loading: true));
    _subscription = watch().listen((records) {
      if (!isClosed) {
        final sorted = [...records]..sort((a, b) => b.id.compareTo(a.id));
        emit(StudentActivityState(records: List.unmodifiable(sorted)));
      }
    }, onError: (Object error) {
      if (!isClosed) emit(const StudentActivityState(failed: true));
    });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
