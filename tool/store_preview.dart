// Capture harness only; not imported by the production entrypoint.
// Uses production components with synthetic fixtures, never Firebase.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/domain/theme_defaults.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/components/system_page.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_cubit/student_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_activity_cubit/student_activity_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/login_page/login_page_widget.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/home_page/home_page_widget.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_info_page/student_directory_view.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_detail_page/student_profile_overview.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/student_info/student_identity_card.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(storePreview(Uri.base.queryParameters['scene'] ?? 'login',
      dark: Uri.base.queryParameters['dark'] == 'true'));
}

Widget storePreview(String scene, {bool dark = false}) {
  final fixtures = [
    for (final entry in [
      (name: '林小禾', gender: '男'),
      (name: '陳小葵', gender: '女'),
      (name: '王小宇', gender: '男')
    ])
      StudentDetail.empty().copyWith(
          id: 'demo-${entry.name}',
          name: entry.name,
          school: '向陽國小',
          gender: entry.gender,
          classLocation: ClassLocation.values.first.name,
          motto: '每天進步一點點。'),
  ];
  return ScreenUtilInit(
      designSize: const Size(2360, 1640),
      builder: (_, __) => MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: SystemTheme(defaultDesignThemes().first, dark).materialTheme(),
          home: scene == 'home'
              ? const HomePageWidget()
              : scene == 'directory'
                  ? SystemPage(
                      title: '學生資料',
                      scaffoldKey: GlobalKey<ScaffoldState>(),
                      onBack: () {},
                      showSaveConfirmation: false,
                      child: StudentDirectoryView(
                          state: StudentsState(fixtures),
                          onCreate: () {},
                          onRetry: () {},
                          itemBuilder: (s, compact) => StudentIdentityCard(
                              student: s,
                              compact: compact,
                              ribbonCount: 8,
                              onOpen: () {},
                              onEdit: () {},
                              onDelete: () {})))
                  : scene == 'profile'
                      ? SystemPage(
                          title: '學生資料',
                          scaffoldKey: GlobalKey<ScaffoldState>(),
                          showSaveConfirmation: false,
                          onBack: () {},
                          child: StudentProfileOverview(
                              student: fixtures.first,
                              activity: const StudentActivityState(),
                              ribbonCount: 8,
                              onEdit: () {},
                              onHistory: () {},
                              onRetry: () {},
                              attachment: const SizedBox.shrink()))
                      : const LoginPageWidget()));
}
