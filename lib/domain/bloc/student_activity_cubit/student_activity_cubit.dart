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
  Completer<void>? _ready;
  int _generation = 0;
  Future<void> load() async {
    if (isClosed || state.loading) return;
    final generation = ++_generation;
    unawaited(_subscription?.cancel());
    emit(const StudentActivityState(loading: true));
    final ready = Completer<void>();
    _ready = ready;
    _subscription = watch().listen((records) {
      if (!isClosed && generation == _generation) {
        final sorted = [...records]..sort((a, b) => b.id.compareTo(a.id));
        emit(StudentActivityState(records: List.unmodifiable(sorted)));
      }
      if (!ready.isCompleted) ready.complete();
    }, onError: (Object error) {
      if (!isClosed && generation == _generation)
        emit(const StudentActivityState(failed: true));
      if (!ready.isCompleted) ready.complete();
    });
    await ready.future;
  }

  @override
  Future<void> close() async {
    _generation++;
    if (_ready?.isCompleted == false) _ready!.complete();
    await _subscription?.cancel();
    await super.close();
  }
}
