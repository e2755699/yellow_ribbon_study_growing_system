import 'dart:async';
import 'dart:collection';
import 'roster_models.dart';

class _Entry<T> {
  final events = StreamController<DataSnapshot<T>>.broadcast(sync: true);
  StreamSubscription<DataSnapshot<T>>? source;
  DataSnapshot<T>? latest;
  int listeners = 0;
  int generation = 0;
}

/// Repository-owned replay cache. No disk storage and no UI dependencies.
class SharedStreamCache<T> {
  final int capacity;
  final _entries = <String, _Entry<T>>{};
  SharedStreamCache({this.capacity = 32});

  Stream<DataSnapshot<T>> watch(
          String key, Stream<DataSnapshot<T>> Function() create) =>
      Stream.multi((out) {
        final entry = _entries.remove(key) ?? _Entry<T>();
        _entries[key] = entry;
        final subscription = entry.events.stream.listen(out.addSync,
            onError: out.addErrorSync, onDone: out.closeSync);
        entry.listeners++;
        if (entry.latest != null) {
          out.addSync(DataSnapshot(entry.latest!.data,
              fromCache: entry.source == null || entry.latest!.fromCache));
        }
        if (entry.source == null) {
          final generation = ++entry.generation;
          entry.source = create().listen((snapshot) {
            if (generation != entry.generation || entry.events.isClosed) return;
            entry.latest = snapshot;
            entry.events.add(snapshot);
          }, onError: (Object error, StackTrace stack) {
            if (generation != entry.generation || entry.events.isClosed) return;
            entry.events.addError(error, stack);
          }, onDone: () {
            if (generation == entry.generation) entry.source = null;
          });
        }
        _trim();
        out.onCancel = () async {
          await subscription.cancel();
          entry.listeners--;
          if (entry.listeners == 0) {
            entry.generation++;
            final source = entry.source;
            entry.source = null;
            await source?.cancel();
            _trim();
          }
        };
      });

  void _trim() {
    for (final key in _entries.keys.toList()) {
      if (_entries.length <= capacity) return;
      final entry = _entries[key]!;
      if (entry.listeners == 0) {
        _entries.remove(key);
        entry.events.close();
      }
    }
  }

  Future<void> clear() async {
    final old = _entries.values.toList();
    _entries.clear();
    for (final entry in old) {
      entry.generation++;
      entry.latest = null;
      final source = entry.source;
      entry.source = null;
      await source?.cancel();
      await entry.events.close();
    }
  }

  int get size => _entries.length;
}
