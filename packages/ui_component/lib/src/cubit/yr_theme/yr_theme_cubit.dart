import 'package:bloc/bloc.dart';
import 'package:flutter/src/material/app.dart';
import 'package:meta/meta.dart';
import 'package:ui_component/ui_component.dart';

part 'yr_theme_state.dart';

class YrThemeCubit extends Cubit<YrThemeState> {
  YrThemeCubit(DsTheme theme) : super(YrThemeInitial(theme));

  void changedMode(ThemeMode themeMode) {
    emit(YrThemeChanged(
        themeMode == ThemeMode.dark ? DsTheme.dark : DsTheme.light));
  }
}
