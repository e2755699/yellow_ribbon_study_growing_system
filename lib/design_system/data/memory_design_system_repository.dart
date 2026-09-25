import 'dart:async';
import '../domain/design_system_repository.dart';
import '../domain/theme_definition.dart';

/// Widgetbook/test adapter. Never initializes or writes Firebase.
class MemoryDesignSystemRepository implements DesignSystemRepository {
  MemoryDesignSystemRepository({this.writable = true});
  final bool writable;
  final _themes = <String, ThemeDefinition>{};
  final _changes =
      StreamController<List<ThemeDefinition>>.broadcast(sync: true);
  @override
  Stream<List<ThemeDefinition>> watchThemes() async* {
    yield _themes.values.toList();
    yield* _changes.stream;
  }

  @override
  Future<bool> canPublish() async => writable;
  @override
  Future<ThemeDefinition> publish(ThemeDefinition theme,
      {required int expectedRevision}) async {
    if (!writable) throw const ThemePermissionDenied();
    if ((_themes[theme.id]?.revision ?? 0) != expectedRevision) {
      throw const ThemeConflict();
    }
    if (theme.validationErrors.isNotEmpty) {
      throw FormatException(theme.validationErrors.join('；'));
    }
    final saved = theme.copyWith(revision: expectedRevision + 1);
    _themes[theme.id] = saved;
    _changes.add(_themes.values.toList());
    return saved;
  }

  Future<void> dispose() => _changes.close();
}
