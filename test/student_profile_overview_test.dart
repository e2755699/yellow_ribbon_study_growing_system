import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_activity_cubit/student_activity_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/performance_rating.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_performance/student_daily_performance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_detail_page/student_profile_overview.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/domain/theme_defaults.dart';

void main() {
  StudentDailyPerformanceRecord record(DateTime date) =>
      StudentDailyPerformanceRecord(
          'fixture', '測試學生', ClassLocation.values.first, PerformanceRating.good,
          recordDate: date, remarks: '上課主動參與討論，願意協助同學完成作業。');

  test('profile activity sorts records and reports failed reads for retry',
      () async {
    var fail = true;
    final cubit = StudentActivityCubit(() async {
      if (fail) throw StateError('offline');
      return [record(DateTime(2026, 8, 1)), record(DateTime(2026, 9, 17))];
    });
    await cubit.load();
    expect(cubit.state.failed, isTrue);
    fail = false;
    await cubit.load();
    expect(cubit.state.failed, isFalse);
    expect(cubit.state.records.first.recordDate, DateTime(2026, 9, 17));
    await cubit.close();
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
