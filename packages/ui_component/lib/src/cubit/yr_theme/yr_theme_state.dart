part of 'yr_theme_cubit.dart';

@immutable
sealed class YrThemeState {
  final DsTheme theme;

  const YrThemeState(this.theme);

  ThemeMode get getThemeMode => theme.isDark ? ThemeMode.dark : ThemeMode.light;
}

final class YrThemeInitial extends YrThemeState {
  const YrThemeInitial(super.theme);
}

final class YrThemeChanged extends YrThemeState {
  const YrThemeChanged(super.theme);
}
