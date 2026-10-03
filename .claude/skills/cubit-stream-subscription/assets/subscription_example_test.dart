import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'subscription_example.dart';

void main() {
  test('setup finishes before first data; subsequent data keeps updating',
      () async {
    final source = StreamController<List<int>>();
    final cubit = SubscriptionExample<int>(() => source.stream);
    await cubit.start();
    expect(cubit.state.loading, isTrue);
    final first = cubit.stream.first;
    source.add([1]);
    expect((await first).records, [1]);
    final second = cubit.stream.first;
    source.add([2]);
    expect((await second).records, [2]);
    final empty = cubit.stream.first;
    source.add([]);
    expect((await empty).records, isEmpty);
    expect(cubit.state.loading, isFalse);
    await cubit.close();
    await source.close();
  });

  test('factory sync failure is state, then retry can succeed', () async {
    var fail = true;
    final cubit = SubscriptionExample<int>(() {
      if (fail) throw StateError('fixture');
      return Stream.value([1]);
    });
    await cubit.start();
    expect(cubit.state.error, isA<StateError>());
    expect(cubit.state.loading, isFalse);
    fail = false;
    final success = cubit.stream.firstWhere((s) => s.records.isNotEmpty);
    await cubit.start();
    expect((await success).error, isNull);
    await cubit.close();
  });

  test('stream errors retain current data and a later event recovers',
      () async {
    final source = StreamController<List<int>>();
    final cubit = SubscriptionExample<int>(() => source.stream);
    await cubit.start();
    final initial = cubit.stream.first;
    source.add([1]);
    await initial;
    final failed = cubit.stream.first;
    source.addError(StateError('fixture'));
    expect((await failed).records, [1]);
    expect(cubit.state.error, isA<StateError>());
    final recovered = cubit.stream.first;
    source.add([2]);
    expect((await recovered).error, isNull);
    await cubit.close();
    await source.close();
  });

  test('empty done stops loading', () async {
    final cubit = SubscriptionExample<int>(() => const Stream.empty());
    final done = cubit.stream.firstWhere((s) => s.done);
    await cubit.start();
    final state = await done;
    expect(state.loading, isFalse);
    expect(state.records, isEmpty);
    expect(state.error, isNull);
    await cubit.close();
  });

  test('done after data preserves data', () async {
    final cubit = SubscriptionExample<int>(() => Stream.value([1]));
    final done = cubit.stream.firstWhere((s) => s.done);
    await cubit.start();
    expect((await done).records, [1]);
    await cubit.close();
  });

  test('done after error does not pretend success', () async {
    final cubit =
        SubscriptionExample<int>(() => Stream.error(StateError('fixture')));
    final done = cubit.stream.firstWhere((s) => s.done);
    await cubit.start();
    expect((await done).error, isA<StateError>());
    await cubit.close();
  });

  test('overlapping starts share cancellation and only latest attaches',
      () async {
    final released = Completer<void>();
    final cancelling = Completer<void>();
    final old = StreamController<List<int>>(onCancel: () {
      cancelling.complete();
      return released.future;
    });
    final next = StreamController<List<int>>();
    var calls = 0;
    final cubit =
        SubscriptionExample<int>(() => ++calls == 1 ? old.stream : next.stream);
    await cubit.start();
    final restart1 = cubit.start();
    await cancelling.future;
    final restart2 = cubit.start();
    expect(calls, 1);
    released.complete();
    await Future.wait([restart1, restart2]);
    expect(calls, 2);
    final received = cubit.stream.first;
    next.add([2]);
    expect((await received).records, [2]);
    await cubit.close();
    await old.close();
    await next.close();
  });

  test('close during restart prevents a new listener', () async {
    final released = Completer<void>();
    final cancelling = Completer<void>();
    final source = StreamController<List<int>>(onCancel: () {
      cancelling.complete();
      return released.future;
    });
    var calls = 0;
    final cubit = SubscriptionExample<int>(() {
      calls++;
      return source.stream;
    });
    await cubit.start();
    final restart = cubit.start();
    await cancelling.future;
    final closing = cubit.close();
    released.complete();
    await Future.wait([restart, closing]);
    await cubit.start();
    expect(calls, 1);
    expect(cubit.isClosed, isTrue);
    await source.close();
  });

  test('close before initial setup prevents subscribing', () async {
    var calls = 0;
    final cubit = SubscriptionExample<int>(() {
      calls++;
      return Stream.value([]);
    });
    final start = cubit.start();
    await cubit.close();
    await start;
    expect(calls, 0);
  });

  test('cancel failure blocks restart and close still closes Cubit', () async {
    final source = StreamController<List<int>>(
        onCancel: () => Future<void>.error(StateError('cleanup')));
    var calls = 0;
    final cubit = SubscriptionExample<int>(() {
      calls++;
      return source.stream;
    });
    await cubit.start();
    await cubit.start();
    expect(cubit.state.error, isA<StateError>());
    await cubit.start();
    expect(calls, 1);
    await expectLater(cubit.close(), throwsStateError);
    expect(cubit.isClosed, isTrue);
    await source.close();
  });

  test('state owns an immutable copy of the emitted list', () async {
    final source = StreamController<List<int>>();
    final cubit = SubscriptionExample<int>(() => source.stream);
    await cubit.start();
    final list = [1];
    final received = cubit.stream.first;
    source.add(list);
    final snapshot = await received;
    list.add(2);
    expect(snapshot.records, [1]);
    expect(() => snapshot.records.add(3), throwsUnsupportedError);
    await cubit.close();
    await source.close();
  });

  test('once adapter is lazy and emits one result then done', () async {
    var calls = 0;
    final stream = once(() async {
      calls++;
      return 7;
    });
    expect(calls, 0);
    expect(await stream.toList(), [7]);
    expect(calls, 1);
  });

  test('once adapter turns synchronous failure into a stream error', () async {
    final stream = once<int>(() => throw StateError('fixture'));
    await expectLater(
        stream, emitsInOrder([emitsError(isA<StateError>()), emitsDone]));
  });
}
