import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_activity_cubit/student_activity_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_state.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_detail_page/student_detail_page_widget.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_detail_page/student_detail_main_section.dart';
import 'domain/bloc/student_detail_cubit_test.dart' show MemoryStudentsRepo;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  setUpAll(() async => Firebase.initializeApp());
  late MemoryStudentsRepo repo;
  late StudentDetailCubit cubit;
  late GoRouter router;
  final name = find.widgetWithText(TextFormField, '名字');

  Future<void> open(WidgetTester tester, {bool create = false}) async {
    tester.view.physicalSize = const Size(1024, 768);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    repo = MemoryStudentsRepo();
    GetIt.I.registerSingleton<StudentsRepo>(repo);
    cubit =
        StudentDetailCubit(StudentDetailInitial(detail: StudentDetail.empty()));
    if (create) {
      cubit.createStudentDetail(operate: Operate.create);
    } else {
      // Older records can lack an enrollment date. Merely displaying the
      // fallback date must not make their profile dirty.
      cubit.loadStudentDetail(
          StudentDetail.empty().copyWith(id: 'synthetic', name: '原本姓名'),
          operate: Operate.edit);
    }
    router = GoRouter(initialLocation: '/home', routes: [
      GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('名冊目的地'))),
      GoRoute(
          path: '/student',
          builder: (_, __) => BlocProvider.value(
              value: cubit,
              child: BlocProvider(
                  create: (_) => StudentActivityCubit(() async => [])..load(),
                  child: const StudentDetailPageWidget()))),
    ]);
    await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(2360, 1640),
        builder: (_, __) => MaterialApp.router(routerConfig: router)));
    router.push('/student');
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester, bool system) async {
    if (system) {
      await tester.binding.handlePopRoute();
    } else {
      await tester.tap(find.byTooltip('返回'));
    }
    await tester.pumpAndSettle();
  }

  tearDown(() async {
    router.dispose();
    await cubit.close();
    await GetIt.I.reset();
  });

  for (final create in [false, true]) {
    for (final system in [false, true]) {
      testWidgets(
          'untouched form exits without dialog or write create=$create system=$system',
          (tester) async {
        await open(tester, create: create);
        await back(tester, system);
        expect(find.text('保存變更'), findsNothing);
        expect(find.text('名冊目的地'), findsOneWidget);
        expect(repo.students, isEmpty);
        expect(repo.updatedStudent, isNull);
      });
    }
  }

  testWidgets('text changed then reverted exits without dialog or write',
      (tester) async {
    await open(tester);
    await tester.enterText(name, '修改姓名');
    await tester.enterText(name, '原本姓名');
    await back(tester, false);
    expect(find.text('保存變更'), findsNothing);
    expect(find.text('名冊目的地'), findsOneWidget);
    expect(repo.students, isEmpty);
  });

  testWidgets(
      'changed text prompts; cancel retains draft; discard never writes',
      (tester) async {
    await open(tester);
    await tester.enterText(name, '修改姓名');
    await back(tester, true);
    expect(find.text('保存變更'), findsOneWidget);
    await tester.tap(find.text('取消'));
    await tester.pumpAndSettle();
    expect(find.text('修改姓名'), findsOneWidget);
    await back(tester, false);
    await tester.tap(find.text('不保存'));
    await tester.pumpAndSettle();
    expect(find.text('名冊目的地'), findsOneWidget);
    expect(repo.students, isEmpty);
  });

  testWidgets('failed save stays dirty; successful retry saves and exits',
      (tester) async {
    await open(tester);
    repo.failUpdate = true;
    await tester.enterText(name, '修改姓名');
    await back(tester, false);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('修改姓名'), findsOneWidget);
    expect(find.text('名冊目的地'), findsNothing);
    repo.failUpdate = false;
    await back(tester, false);
    expect(find.text('保存變更'), findsOneWidget);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(repo.updatedStudent?.name, '修改姓名');
    expect(find.text('名冊目的地'), findsOneWidget);
  });

  testWidgets(
      'invalid changed form prompts before validation and preserves text',
      (tester) async {
    await open(tester);
    await tester.enterText(name, '');
    await back(tester, false);
    expect(find.text('保存變更'), findsOneWidget);
    expect(find.text('請輸入學生姓名'), findsNothing);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();
    expect(find.text('請輸入學生姓名'), findsOneWidget);
    expect(repo.students, isEmpty);
  });

  testWidgets('selection change is dirty and reverting it is clean',
      (tester) async {
    await open(tester);
    final form = tester.state<StudentDetailMainSectionState>(
        find.byType(StudentDetailMainSection));
    final gender = find.byWidgetPredicate((w) =>
        w is DropdownButtonFormField<String> && w.decoration.labelText == '性別');
    final original = cubit.state.detail.gender;
    await tester.tap(gender);
    await tester.pumpAndSettle();
    await tester.tap(find.text(original == '男' ? '女' : '男').last);
    await tester.pumpAndSettle();
    expect(form.hasUnsavedChanges, isTrue);
    await tester.tap(gender);
    await tester.pumpAndSettle();
    await tester.tap(find.text(original).last);
    await tester.pumpAndSettle();
    expect(form.hasUnsavedChanges, isFalse);
    await back(tester, false);
    expect(find.text('名冊目的地'), findsOneWidget);
  });
}
