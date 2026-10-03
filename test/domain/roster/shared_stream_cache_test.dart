import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/shared_stream_cache.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_models.dart';

void main() {
  test('shared listeners use one source; reopened cached data is marked stale',
      () async {
    final cache = SharedStreamCache<int>(capacity: 2);
    final sources = <StreamController<DataSnapshot<int>>>[];
    Stream<DataSnapshot<int>> create() {
      final source = StreamController<DataSnapshot<int>>.broadcast();
      sources.add(source);
      return source.stream;
    }

    final a = <DataSnapshot<int>>[], b = <DataSnapshot<int>>[];
    final one = cache.watch('user/site/date', create).listen(a.add);
    final two = cache.watch('user/site/date', create).listen(b.add);
    expect(sources.length, 1);
    sources.single.add(const DataSnapshot(1));
    await Future<void>.delayed(Duration.zero);
    expect(a.single.data, 1);
    expect(b.single.data, 1);
    await one.cancel();
    await two.cancel();
    final reopened = cache.watch('user/site/date', create).listen(a.add);
    await Future<void>.delayed(Duration.zero);
    expect(sources.length, 2);
    expect(a.last.fromCache, isTrue);
    await reopened.cancel();
    await cache.clear();
    for (final source in sources) {
      await source.close();
    }
  });
  test('cache clears on identity change and evicts inactive old dates',
      () async {
    final cache = SharedStreamCache<int>(capacity: 2);
    for (var i = 0; i < 5; i++) {
      final sub = cache
          .watch('date$i', () => Stream.value(DataSnapshot(i)))
          .listen((_) {});
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();
    }
    expect(cache.size, 2);
    await cache.clear();
    expect(cache.size, 0);
  });
}
