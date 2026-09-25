import 'package:flutter/material.dart';
import '../../design_system/domain/theme_defaults.dart';
import '../../design_system/domain/theme_definition.dart';
import '../../design_system/presentation/system_theme.dart';

/// Homepage-only tokens: other screens and the existing layout keep their theme.
enum HomeColorTheme {
  caramel,
  olive,
  teal,
  original;

  static final _seeds = {
    for (final theme in defaultDesignThemes()) theme.id: theme
  };
  ThemeDefinition get definition => _seeds[name]!;
  String get label => definition.name;
  Color get card => tokenColor(definition.light['primary']!);
  Color get foreground => tokenColor(definition.light['onPrimary']!);
  Color get detail => tokenColor(definition.light['detail']!);

  static const preferenceKey = 'home_color_theme';
  static const defaultTheme = HomeColorTheme.caramel;
  static const controlSurface = Color(0xFFFFF9ED);
  static const controlText = Color(0xFF49362C);
  static const transparent = Color(0x00000000);

  Color get hover => _darken(0.08);
  Color get pressed => _darken(0.12);

  Color _darken(double amount) => Color.fromARGB(
        card.alpha,
        (card.red * (1 - amount)).round(),
        (card.green * (1 - amount)).round(),
        (card.blue * (1 - amount)).round(),
      );

  Color backgroundFor(Set<WidgetState> states) {
    if (states.contains(WidgetState.pressed)) return pressed;
    if (states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused)) return hover;
    return card;
  }

  static HomeColorTheme fromPreference(String? value) =>
      values.where((theme) => theme.name == value).firstOrNull ?? defaultTheme;
}
