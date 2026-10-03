import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/domain/utils/request_timeout.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_activity_cubit/student_activity_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_models.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_command_failure.dart';

void main() {
  testWidgets(
      'future waits 59 seconds and times out at 60; late result is ignored',
      (tester) async {
    final pending = Completer<int>();
    Object? failure;
    int? value;
    pending.future.withRequestTimeout().then<void>((v) {
      value = v;
    }, onError: (Object error) {
      failure = error;
    });
    await tester.pump(const Duration(seconds: 59));
    expect(failure, isNull);
    await tester.pump(const Duration(seconds: 1));
    expect(failure, isA<RequestTimeoutException>());
    pending.complete(1);
    await tester.pump();
    expect(value, isNull);
    expect(
        const RosterCommandFailure('deadline-exceeded').outcomeUnknown, isTrue);
  });

  testWidgets('a successful future does not later time out', (tester) async {
    final pending = Completer<int>();
    Object? failure;
    int? value;
    pending.future.withRequestTimeout().then<void>((v) {
      value = v;
    }, onError: (Object error) {
      failure = error;
    });
    pending.complete(7);
    await tester.pump();
    await tester.pump(const Duration(seconds: 61));
    expect(value, 7);
    expect(failure, isNull);
  });

  testWidgets('initial timeout reports once and allows late recovery',
      (tester) async {
    final source = StreamController<int>();
    final errors = <Object>[], values = <int>[];
    final sub = source.stream
        .withInitialResponseTimeout()
        .listen(values.add, onError: errors.add);
    await tester.pump(const Duration(seconds: 59));
    expect(errors, isEmpty);
    await tester.pump(const Duration(seconds: 1));
    expect(errors.single, isA<RequestTimeoutException>());
    source.add(1);
    await tester.pump();
    await tester.pump(const Duration(seconds: 120));
    source.add(2);
    await tester.pump();
    expect(values, [1, 2]);
    expect(errors, hasLength(1));
    await tester.runAsync(() => sub.cancel());
    await tester.runAsync(() => source.close());
  });

  testWidgets('healthy idle subscription has no recurring deadline',
      (tester) async {
    final source = StreamController<int>();
    final errors = <Object>[];
    final sub = source.stream
        .withInitialResponseTimeout()
        .listen((_) {}, onError: errors.add);
    source.add(1);
    await tester.pump();
    await tester.pump(const Duration(minutes: 5));
    expect(errors, isEmpty);
    await tester.runAsync(() => sub.cancel());
    await tester.runAsync(() => source.close());
  });

  testWidgets('cached values do not satisfy a server-only initial deadline',
      (tester) async {
    final source = StreamController<bool>();
    final errors = <Object>[];
    final sub = source.stream
        .withInitialResponseTimeout(isReady: (server) => server)
        .listen((_) {}, onError: errors.add);
    source.add(false);
    await tester.pump();
    await tester.pump(requestTimeout);
    expect(errors.single, isA<RequestTimeoutException>());
    await tester.runAsync(() => sub.cancel());
    await tester.runAsync(() => source.close());
  });

  testWidgets('cancel before first data cancels the deadline too',
      (tester) async {
    final source = StreamController<int>();
    final errors = <Object>[];
    final sub = source.stream
        .withInitialResponseTimeout()
        .listen((_) {}, onError: errors.add);
    await tester.runAsync(() => sub.cancel());
    await tester.pump(requestTimeout);
    expect(source.hasListener, isFalse);
    expect(errors, isEmpty);
    await tester.runAsync(() => source.close());
  });

  testWidgets('activity timeout clears loading and retry receives a new source',
      (tester) async {
    final sources = [
      StreamController<List<DailyRecord>>(),
      StreamController<List<DailyRecord>>()
    ];
    var starts = 0;
    final cubit = StudentActivityCubit.watching(() => sources[starts++].stream);
    cubit.load();
    await tester.pump(requestTimeout);
    expect(cubit.state.loading, isFalse);
    expect(cubit.state.failed, isTrue);
    cubit.load();
    expect(sources.first.hasListener, isFalse);
    sources.last.add([]);
    await tester.pump();
    expect(cubit.state.failed, isFalse);
    expect(cubit.state.loading, isFalse);
    await tester.runAsync(() => cubit.close());
    for (final source in sources) {
      await tester.runAsync(() => source.close());
    }
  });

  testWidgets('activity handles synchronous factory failure and empty done',
      (tester) async {
    final broken =
        StudentActivityCubit.watching(() => throw StateError('offline'));
    broken.load();
    expect(broken.state.failed, isTrue);
    await tester.runAsync(() => broken.close());
    final empty = StudentActivityCubit.watching(() => const Stream.empty());
    empty.load();
    await tester.pump();
    expect(empty.state.loading, isFalse);
    expect(empty.state.failed, isTrue);
    await tester.runAsync(() => empty.close());
  });
}
