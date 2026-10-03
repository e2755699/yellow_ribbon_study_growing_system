import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_activity_cubit/student_activity_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_state.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/roster/roster_models.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_detail_page/student_detail_page_widget.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_detail_page/student_detail_main_section.dart';
import 'domain/bloc/student_detail_cubit_test.dart' show MemoryStudentsRepo;
import 'domain/bloc/student_detail_recovery_test.dart'
    show RecoveryStudentsRepo;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  setUpAll(() async {
    await Firebase.initializeApp();
  });
  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('profile stream failure retains unsaved text in the real form',
      (tester) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = RecoveryStudentsRepo();
    GetIt.I.registerSingleton<StudentsRepo>(repo);
    final cubit =
        StudentDetailCubit(StudentDetailInitial(detail: StudentDetail.empty()));
    await tester.runAsync(() async {
      final loading = cubit.loadStudentById('synthetic', operate: Operate.edit);
      await Future<void>.delayed(Duration.zero);
      repo.source.add(StudentDetail.empty().copyWith(
          id: 'synthetic',
          name: 'Original',
          locationId: 'demo',
          classLocation: '合成據點',
          enrollmentStartDate: '2026-10-01'));
      await loading;
    });
    await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(2360, 1640),
        builder: (_, __) => MaterialApp(
            home: BlocProvider.value(
                value: cubit,
                child: BlocProvider(
                    create: (_) => StudentActivityCubit(() async => [])..load(),
                    child: const StudentDetailPageWidget())))));
    await tester.pumpAndSettle();
    final name = find.widgetWithText(TextFormField, '名字');
    await tester.enterText(name, '尚未儲存的姓名');
    repo.source.addError(TimeoutException('temporary network failure'));
    await tester.pumpAndSettle();
    expect(cubit.state.isEdit, true);
    expect(cubit.hasUnsavedChanges(), true);
    expect(find.text('尚未儲存的姓名'), findsOneWidget);
    final form = tester.state<StudentDetailMainSectionState>(
        find.byType(StudentDetailMainSection));
    expect(await form.saveForm(), true);
    expect(repo.updatedStudent!.name, '尚未儲存的姓名');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await cubit.close();
      await repo.source.close();
    });
  });

  for (final size in [
    const Size(1024, 768),
    const Size(768, 1024),
    const Size(507, 768)
  ]) {
    testWidgets('student form is scrollable without overflow at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = MemoryStudentsRepo();
      GetIt.I.registerSingleton<StudentsRepo>(repo);
      final cubit = StudentDetailCubit(StudentDetailLoaded(
          detail: StudentDetail.empty().copyWith(
              locationId: 'demo',
              classLocation: '合成據點',
              enrollmentStartDate: '2026-10-02'),
          operate: Operate.create))
        ..sites = const [ClassSite('demo', '合成據點')];
      await tester.pumpWidget(ScreenUtilInit(
          designSize: const Size(2360, 1640),
          builder: (_, __) => MaterialApp(
                home: BlocProvider.value(
                    value: cubit,
                    child: BlocProvider(
                        create: (_) =>
                            StudentActivityCubit(() async => [])..load(),
                        child: const StudentDetailPageWidget())),
              )));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(find.widgetWithText(TextFormField, '名字'), '測試學生');
      await tester.enterText(
          find.byKey(const Key('student-motto-input')), '  勇敢嘗試，每天進步一點點！  ');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('個人檔案'), 500,
          scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('個人檔案')).overlaps(Offset.zero & size),
          isTrue);
      expect(tester.takeException(), isNull);
      final form = tester.state<StudentDetailMainSectionState>(
          find.byType(StudentDetailMainSection));
      repo.createResult = null;
      expect(await form.saveForm(), isFalse);
      await tester.pumpAndSettle();
      expect(cubit.state, isA<StudentDetailError>());
      expect(cubit.state.detail.name, '測試學生');
      expect(cubit.state.detail.motto, '勇敢嘗試，每天進步一點點！');
      repo.createResult = 'created-fixture';
      expect(await form.saveForm(), isTrue);
      await tester.pumpAndSettle();
      expect(cubit.state.detail.id, 'created-fixture');
      expect(cubit.state.isView, isTrue);
      expect(repo.students['created-fixture']?.name, '測試學生');
      expect(repo.students['created-fixture']?.motto, '勇敢嘗試，每天進步一點點！');
      expect(find.text('勇敢嘗試，每天進步一點點！'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('student-profile-overview')), findsOneWidget);
      await tester.tap(find.text('編輯資料'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextFormField, '測試學生'), findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, '勇敢嘗試，每天進步一點點！'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('student-motto-input')), '   ');
      FocusManager.instance.primaryFocus?.unfocus();
      expect(
          await tester
              .state<StudentDetailMainSectionState>(
                  find.byType(StudentDetailMainSection))
              .saveForm(),
          isTrue);
      await tester.pumpAndSettle();
      expect(repo.students['created-fixture']?.motto, isEmpty);
      expect(find.text('每天都是，\n更棒的自己！'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await cubit.close();
      await GetIt.I.reset();
    });
  }
}
