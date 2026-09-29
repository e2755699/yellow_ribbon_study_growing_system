import 'dart:async';

import '../enum/class_location.dart';
import 'contracts/class_location_repository.dart';

/// In-memory list for tests and Widgetbook; [set] pushes a change to watchers.
class MemoryClassLocationRepository implements ClassLocationRepository {
  MemoryClassLocationRepository([this._locations = ClassLocation.seeds]);
  List<ClassLocation> _locations;
  final _changes = StreamController<List<ClassLocation>>.broadcast();

  void set(List<ClassLocation> locations) {
    _locations = locations;
    _changes.add(locations);
  }

  @override
  Stream<List<ClassLocation>> watch() async* {
    yield _locations;
    yield* _changes.stream;
  }
}
