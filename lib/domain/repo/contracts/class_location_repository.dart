import '../../enum/class_location.dart';

abstract interface class ClassLocationRepository {
  /// Live list ordered for display; emits again whenever the list changes.
  Stream<List<ClassLocation>> watch();
}
