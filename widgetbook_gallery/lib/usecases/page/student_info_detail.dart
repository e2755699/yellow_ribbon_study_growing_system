import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:yellow_ribbon_study_growing_system/page/main_screen.dart';
import 'package:yellow_ribbon_study_growing_system/enum/yr_page.dart';

import 'package:ui_component/ui_component.dart';

@widgetbook.UseCase(name: 'main page', type: MainScreen)
Widget buildLightTextField(BuildContext context) {
  return BlocProvider(
      create: (BuildContext context) {
        return YrThemeCubit(DsTheme.light);
      },
      child: const MainScreen(page: YrPage.studentInfo));
}
