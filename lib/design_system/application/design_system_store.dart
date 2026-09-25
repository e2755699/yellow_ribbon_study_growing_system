import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/design_system_repository.dart';
import '../domain/theme_defaults.dart';
import '../domain/theme_definition.dart';

/// App-wide published catalog. Editor drafts are deliberately held elsewhere.
class DesignSystemStore extends ChangeNotifier {
  DesignSystemStore(this.repository);
  final DesignSystemRepository repository;
  final _defaults = {
    for (final theme in defaultDesignThemes()) theme.id: theme
  };
  Map<String, ThemeDefinition> _remote = {};
  StreamSubscription<List<ThemeDefinition>>? _subscription;
  bool _disposed = false;
  bool loaded = false;
  String? loadError;
  String activeId = 'caramel';
  bool _selected = false;
  Future<void> _pendingPreference = Future.value();
  ThemeDefinition theme(String id) =>
      _remote[id] ?? _defaults[id] ?? _defaults.values.first;
  ThemeDefinition get active => theme(activeId);
  bool get hasPublishedActive => _remote.containsKey(activeId);
  bool contains(String id) =>
      _remote.containsKey(id) || _defaults.containsKey(id);
  List<ThemeDefinition> get themes {
    final custom = _remote.values
        .where((theme) => !_defaults.containsKey(theme.id))
        .toList()
      ..sort((a, b) {
        final byName = a.name.compareTo(b.name);
        return byName == 0 ? a.id.compareTo(b.id) : byName;
      });
    return [..._defaults.keys.map(theme), ...custom];
  }

  Future<void> start() async {
    if (_subscription != null || _disposed) return;
    _subscription = repository.watchThemes().listen((themes) {
      if (_disposed) return;
      _remote = {for (final theme in themes) theme.id: theme};
      loaded = true;
      loadError = null;
      notifyListeners();
    }, onError: (Object error) {
      if (_disposed) return;
      loaded = false;
      loadError = '雲端主題讀取失敗，目前使用可用的配色。請檢查連線與存取權限。';
      notifyListeners();
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('home_color_theme');
      if (!_disposed &&
          !_selected &&
          saved != null &&
          ThemeDefinition.validId(saved)) {
        activeId = saved;
        notifyListeners();
      }
    } catch (_) {
      /* Local settings are optional; bundled defaults remain usable. */
    }
  }

  void select(String id) {
    if (!contains(id)) return;
    _selected = true;
    activeId = id;
    notifyListeners();
    _pendingPreference = _pendingPreference.then((_) async {
      try {
        await (await SharedPreferences.getInstance())
            .setString('home_color_theme', id);
      } catch (_) {/* The current session still uses the selection. */}
    });
  }

  Future<void> retry() async {
    await _subscription?.cancel();
    _subscription = null;
    loaded = false;
    loadError = null;
    if (!_disposed) notifyListeners();
    await start();
  }

  void acceptPublished(ThemeDefinition theme) {
    if (_disposed) return;
    if ((_remote[theme.id]?.revision ?? 0) > theme.revision) return;
    _remote = {..._remote, theme.id: theme};
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    super.dispose();
  }
}
