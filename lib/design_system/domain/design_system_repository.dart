import 'theme_definition.dart';

abstract interface class DesignSystemRepository {
  /// Empty remote catalog means bundled defaults, not an implicit create.
  Stream<List<ThemeDefinition>> watchThemes();
  Future<bool> canPublish();

  /// Compare-and-swap: implementations MUST enforce expectedRevision atomically.
  Future<ThemeDefinition> publish(ThemeDefinition theme,
      {required int expectedRevision});
}

class ThemeConflict implements Exception {
  const ThemeConflict();
}

class ThemePermissionDenied implements Exception {
  const ThemePermissionDenied();
}
