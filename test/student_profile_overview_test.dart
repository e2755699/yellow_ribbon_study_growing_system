import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_activity_cubit/student_activity_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/roster/roster_models.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_detail_page/student_profile_overview.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/domain/theme_defaults.dart';

void main() {
  testWidgets('student detail uses the shared theme text tones',
      (tester) async {
    final definition = defaultDesignThemes().first;
    final theme = SystemTheme(definition, false);
    await tester.pumpWidget(MaterialApp(
      theme: theme.materialTheme(),
      home: Scaffold(
        body: StudentProfileOverview(
          student: StudentDetail.empty().copyWith(name: '字色測試'),
          activity: const StudentActivityState(),
          ribbonCount: 0,
          onEdit: () {},
          onHistory: null,
          onRetry: () {},
          attachment: const SizedBox(),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.text('字色測試')).style?.color,
        theme.color('primaryText'));
    expect(tester.widget<Text>(find.text('學生檔案')).style?.color,
        theme.color('secondaryText'));
    await tester.scrollUntilVisible(find.text('基本資料'), 200,
        scrollable: find.byType(Scrollable).first);
    expect(tester.widget<Text>(find.text('基本資料')).style?.color,
        theme.color('primaryText'));
    expect(theme.color('primaryText'), isNot(Colors.black));
  });

  DailyRecord record(DateTime date) => DailyRecord('performance',
      studentId: 'fixture',
      locationId: 'demo',
      date: BusinessDate.fromCalendar(date),
      values: {'performanceRating': 'good', 'remarks': '上課主動參與討論，願意協助同學完成作業。'});

  test('profile activity sorts records and reports failed reads for retry',
      () async {
    var fail = true;
    final cubit = StudentActivityCubit(() async {
      if (fail) throw StateError('offline');
      return [record(DateTime(2026, 8, 1)), record(DateTime(2026, 9, 17))];
    });
    final failed = cubit.stream.firstWhere((state) => state.failed);
    cubit.load();
    await failed;
    expect(cubit.state.failed, isTrue);
    fail = false;
    final loaded = cubit.stream.firstWhere((state) => !state.loading);
    cubit.load();
    await loaded;
    expect(cubit.state.failed, isFalse);
    expect(cubit.state.records.first.date.calendar, DateTime(2026, 9, 17));
    await cubit.close();
  });

  test('closing before the first activity event cancels the subscription',
      () async {
    final source = StreamController<List<DailyRecord>>();
    final cubit = StudentActivityCubit.watching(() => source.stream);
    cubit.load();
    expect(source.hasListener, isTrue);
    await cubit.close();
    expect(source.hasListener, isFalse);
    source.add([record(DateTime(2026, 9, 17))]);
    await source.close();
    expect(cubit.isClosed, isTrue);
  });

  test('reloading cancels the old source and receives only the new source',
      () async {
    final oldSource = StreamController<List<DailyRecord>>();
    final newSource = StreamController<List<DailyRecord>>();
    var starts = 0;
    final cubit = StudentActivityCubit.watching(
        () => starts++ == 0 ? oldSource.stream : newSource.stream);
    final initial = cubit.stream.firstWhere((state) => !state.loading);
    cubit.load();
    oldSource.add([record(DateTime(2026, 8, 1))]);
    await initial;

    // Queue an old event before cancellation to verify it cannot win the reload.
    oldSource.add([record(DateTime(2026, 8, 2))]);
    final refreshed = cubit.stream.firstWhere((state) => !state.loading);
    cubit.load();
    expect(oldSource.hasListener, isFalse);
    newSource.add([record(DateTime(2026, 9, 17))]);
    expect(
        (await refreshed).records.single.date.calendar, DateTime(2026, 9, 17));

    await cubit.close();
    expect(newSource.hasListener, isFalse);
    await oldSource.close();
    await newSource.close();
  });

  for (final size in [
    const Size(1024, 768),
    const Size(768, 1024),
    const Size(1194, 834),
    const Size(834, 1194),
    const Size(507, 768)
  ]) {
    testWidgets('overview and contact details remain usable at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var edits = 0;
      var history = 0;
      await tester.pumpWidget(MaterialApp(
        theme: SystemTheme(defaultDesignThemes().first, false).materialTheme(),
        home: Scaffold(
            body: Padding(
          padding: const EdgeInsets.all(16),
          child: StudentProfileOverview(
            student: StudentDetail.empty().copyWith(
                id: 'fixture-student-id',
                name: '測試學生',
                motto: '勇敢嘗試新的挑戰，保持好奇、關心身邊的人，每一天都比昨天更進步一點點。',
                guardianName: '測試監護人',
                guardianPhone: '0900000000',
                school: '測試國民小學'),
            activity:
                StudentActivityState(records: [record(DateTime(2026, 9, 17))]),
            ribbonCount: 8,
            onEdit: () => edits++,
            onHistory: () => history++,
            onRetry: () {},
            attachment: const Text('個人檔案測試區'),
          ),
        )),
      ));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('勇敢嘗試新的挑戰，保持好奇、關心身邊的人，每一天都比昨天更進步一點點。'), findsOneWidget);
      await tester.tap(find.text('編輯資料'));
      expect(edits, 1);
      await tester.ensureVisible(find.text('查看更多').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('查看更多').first);
      expect(history, 1);
      await tester.scrollUntilVisible(find.text('家庭與聯絡人'), 300,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.text('家庭與聯絡人'));
      await tester.pumpAndSettle();
      expect(find.text('0900000000'), findsOneWidget);
      await tester.scrollUntilVisible(find.text('個人檔案測試區'), 500,
          scrollable: find.byType(Scrollable).first);
      expect(find.text('個人檔案測試區').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
