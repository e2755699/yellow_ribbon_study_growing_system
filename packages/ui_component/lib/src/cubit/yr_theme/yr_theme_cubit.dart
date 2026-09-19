import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:ui_component/ui_component.dart';

part 'yr_theme_state.dart';

class YrThemeCubit extends Cubit<YrThemeState> {
  YrThemeCubit(DsTheme theme) : super(YrThemeInitial(theme));

  void changedMode(ThemeMode themeMode) {
    emit(YrThemeChanged(
        themeMode == ThemeMode.dark ? DsTheme.dark : DsTheme.light));
  }
}
