import '../../utils/subscription_failure.dart';
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../roster/roster_models.dart';
import '../../utils/request_timeout.dart';

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
    emit(StudentActivityState(records: state.records, loading: true));
    try {
      _subscription = watch().withInitialResponseTimeout().listen((records) {
        if (!isClosed) {
          final sorted = [...records]..sort((a, b) => b.id.compareTo(a.id));
          emit(StudentActivityState(records: List.unmodifiable(sorted)));
        }
      }, onError: (Object error) {
        if (!isClosed)
          emit(StudentActivityState(
              records: clearsSubscriptionData(error) ? const [] : state.records,
              failed: true));
      });
    } catch (error) {
      if (!isClosed)
        emit(StudentActivityState(
            records: clearsSubscriptionData(error) ? const [] : state.records,
            failed: true));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await super.close();
  }
}
