import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Teaching example: one read-only scope per Cubit, no editable drafts.
/// Recreate the Cubit for a new account/query; adapt policy before production use.
class FeedState<T> {
  FeedState({
    required Iterable<T> records,
    this.loading = false,
    this.error,
    this.done = false,
  }) : records = List<T>.unmodifiable(records);

  final List<T> records;
  final bool loading;
  final Object? error;
  final bool done;
}

/// A finite adapter, not a live backend. Cancellation does not abort [fetch].
Stream<T> once<T>(Future<T> Function() fetch) async* {
  yield await fetch();
}

class SubscriptionExample<T> extends Cubit<FeedState<T>> {
  SubscriptionExample(this.watch) : super(FeedState<T>(records: <T>[]));

  final Stream<List<T>> Function() watch;
  StreamSubscription<List<T>>? _subscription;
  Future<void> _cleanup = Future<void>.value();
  Future<void>? _closing;
  bool _disposed = false;
  int _generation = 0;

  bool _current(int generation) =>
      !_disposed && !isClosed && generation == _generation;

  // Share in-flight cleanup so concurrent starts cannot bypass it.
  // Failed cleanup stays failed: do not add another listener with unknown ownership.
  Future<void> _cancelCurrent() {
    final previous = _subscription;
    _subscription = null;
    if (previous != null) {
      _cleanup = _cleanup.then((_) => previous.cancel());
    }
    return _cleanup;
  }

  /// Completes after setup (or setup failure), not after the first snapshot.
  /// Explicit policy: latest start wins; a restart clears the displayed list.
  Future<void> start() async {
    if (_disposed || isClosed) return;
    final generation = ++_generation;
    emit(FeedState<T>(records: <T>[], loading: true));
    try {
      await _cancelCurrent();
      if (!_current(generation)) return;
      var receivedEvent = false;
      _subscription = watch().listen(
        (records) {
          if (!_current(generation)) return;
          receivedEvent = true;
          emit(FeedState<T>(records: records));
        },
        onError: (Object error, StackTrace stack) {
          if (!_current(generation)) return;
          receivedEvent = true;
          // Product UI maps error to a safe message; diagnostics follow its policy.
          emit(FeedState<T>(records: state.records, error: error));
        },
        onDone: () {
          if (!_current(generation)) return;
          emit(FeedState<T>(
            records: receivedEvent ? state.records : <T>[],
            error: state.error,
            done: true,
          ));
        },
      );
    } catch (error) {
      // Includes source factory/listen throws and cleanup failure.
      if (_current(generation)) {
        emit(FeedState<T>(records: state.records, error: error, done: true));
      }
    }
  }

  @override
  Future<void> close() {
    if (_closing != null) return _closing!;
    _disposed = true;
    _generation++;
    return _closing = _cancelCurrent().whenComplete(() => super.close());
  }
}
