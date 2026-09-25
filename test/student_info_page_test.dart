import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_cubit/student_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/nav/nav.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_info_page/student_info_page_widget.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/student_info/student_info_card.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/domain/theme_defaults.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';

class ListStudentsRepo implements StudentsRepo {
  Future<List<StudentDetail>> Function() fetch = () async => [];
  @override
  Future<List<StudentDetail>> load() => fetch();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  setUpAll(() async {
    await Firebase.initializeApp();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/firebase_analytics'),
            (_) async => null);
  });
  late ListStudentsRepo repo;
  setUp(() {
    repo = ListStudentsRepo();
    GetIt.I.registerSingleton<StudentsRepo>(repo);
  });
  tearDown(() => GetIt.I.reset());

  for (final size in [
    const Size(1024, 768),
    const Size(768, 1024),
    const Size(1194, 834),
    const Size(834, 1194),
    const Size(507, 768),
  ]) {
    testWidgets('student route renders toolbar and returns home at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final auth = AppStateNotifier(
          signedInChanges: const Stream.empty(), initiallySignedIn: true);
      final router = createRouter(auth);
      addTearDown(router.dispose);
      addTearDown(auth.dispose);
      await tester.pumpWidget(ScreenUtilInit(
          designSize: const Size(2360, 1640),
          builder: (_, __) => MaterialApp.router(routerConfig: router)));
      await tester.pumpAndSettle();
      await tester.tap(find.text('學生資料'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('新增學生資料').hitTestable(), findsOneWidget);
      expect(find.textContaining('目前沒有學生資料'), findsOneWidget);
      await tester.tap(find.byTooltip('返回'));
      await tester.pumpAndSettle();
      expect(find.text('每日出席'), findsOneWidget);
      expect(find.byType(StudentInfoPageWidget), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('loading, read failure and retry have distinct visible states',
      (tester) async {
    final pending = Completer<List<StudentDetail>>();
    repo.fetch = () => pending.future;
    final cubit = StudentsCubit(StudentsState([]));
    addTearDown(cubit.close);
    final load = cubit.load();
    await tester.pumpWidget(ScreenUtilInit(
        designSize: const Size(2360, 1640),
        builder: (_, __) => MaterialApp(
              home: BlocProvider.value(
                  value: cubit, child: const StudentInfoPageWidget()),
            )));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.completeError(FirebaseException(
        plugin: 'cloud_firestore', code: 'permission-denied'));
    await load;
    await tester.pumpAndSettle();
    expect(find.textContaining('存取權限'), findsOneWidget);
    expect(find.textContaining('目前沒有學生資料'), findsNothing);
    repo.fetch = () async => [];
    await tester.tap(find.text('重新載入'));
    await tester.pumpAndSettle();
    expect(find.textContaining('目前沒有學生資料'), findsOneWidget);
    expect(find.textContaining('存取權限'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  test('returning while a student load is pending does not emit after close',
      () async {
    final pending = Completer<List<StudentDetail>>();
    repo.fetch = () => pending.future;
    final cubit = StudentsCubit(StudentsState([]));
    final load = cubit.load();
    await cubit.close();
    pending.complete([]);
    await expectLater(load, completes);
  });

  for (final size in [
    const Size(1024, 768),
    const Size(768, 1024),
    const Size(1194, 834),
    const Size(834, 1194),
    const Size(507, 768)
  ]) {
    for (final dark in [false, true]) {
      testWidgets(
          'populated directory search, views and tokens at $size dark=$dark',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final cubit = StudentsCubit(StudentsState([
          StudentDetail.empty().copyWith(name: '測試同學', school: '向陽國小'),
          StudentDetail.empty()
              .copyWith(name: '另一據點同學', school: '樹林國小', classLocation: '台南北區'),
        ]));
        addTearDown(cubit.close);
        final ds = SystemTheme(defaultDesignThemes()[1], dark);
        await tester.pumpWidget(MaterialApp(
            theme: ds.materialTheme(),
            home: BlocProvider.value(
                value: cubit, child: const StudentInfoPageWidget())));
        await tester.pumpAndSettle();
        expect(find.text('測試同學'), findsOneWidget);
        expect(find.text('另一據點同學'), findsNothing);
        expect(tester.takeException(), isNull);
        final card = tester.widget<Material>(find
            .descendant(
                of: find.byType(StudentInfoCard),
                matching: find.byType(Material))
            .first);
        expect(card.color, ds.color('secondaryBackground'));
        await tester.tap(find.text('列表'));
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<StudentInfoCard>(find.byType(StudentInfoCard))
                .compact,
            isTrue);
        expect(tester.takeException(), isNull);
        await tester.enterText(find.byType(TextField), '向陽');
        await tester.pumpAndSettle();
        expect(find.text('測試同學'), findsOneWidget);
        await tester.enterText(find.byType(TextField), '沒有這個名字');
        await tester.pumpAndSettle();
        expect(find.text('找不到符合搜尋條件的學生'), findsOneWidget);
        await tester.tap(find.byTooltip('清除搜尋'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(DropdownButtonFormField<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text('全部據點').last);
        await tester.pumpAndSettle();
        expect(find.text('另一據點同學'), findsOneWidget);
        await tester.tap(find.text('卡片'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
