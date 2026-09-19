import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import '../application/design_system_store.dart';
import 'system_theme.dart';

/// App adapter only. Product components consume SystemTheme.of(context), never
/// GetIt or editor drafts. Widgetbook can supply ThemeData without a backend.
class SystemThemeScope extends StatelessWidget {
  const SystemThemeScope({super.key, required this.builder});
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    if (!GetIt.I.isRegistered<DesignSystemStore>()) {
      return _wrap(SystemTheme.of(context));
    }
    final store = GetIt.I<DesignSystemStore>();
    return AnimatedBuilder(
        animation: store,
        builder: (context, _) => _wrap(SystemTheme(
            store.active, Theme.of(context).brightness == Brightness.dark)));
  }

  Widget _wrap(SystemTheme theme) =>
      Theme(data: theme.materialTheme(), child: Builder(builder: builder));
}
