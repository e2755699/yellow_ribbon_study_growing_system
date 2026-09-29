import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/performance_rating.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_performance/student_daily_performance_info.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/daily_performance_page/daily_performance_page_widget.dart';

void main() {
  StudentDailyPerformanceRecord fixture() => StudentDailyPerformanceRecord(
      'fixture', '測試學生', ClassLocation.values.first, PerformanceRating.average);

  Future<void> pumpCard(
      WidgetTester tester, StudentDailyPerformanceRecord r, Size size) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: SizedBox(
                    // 與頁面相同：左右各 16 內距，可用寬度 >= 1000 時兩欄、間距 20。
                    width: size.width - 32 >= 1000
                        ? (size.width - 52) / 2
                        : size.width - 32,
                    child: DailyPerformanceRecordCard(r))))));
    await tester.pumpAndSettle();
  }

  for (final size in const [
    Size(1194, 834),
    Size(1024, 768),
    Size(834, 1194),
    Size(768, 1024),
    Size(507, 768),
  ]) {
    testWidgets('expand opens fullscreen and edits sync back ($size)',
        (tester) async {
      final record = fixture();
      await pumpCard(tester, record, size);

      await tester.tap(find.byTooltip('放大編輯'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byTooltip('縮小'), findsOneWidget);

      // 全螢幕內輸入描述，列表卡片同步顯示。
      final fullscreenField = find.descendant(
          of: find.byType(Dialog), matching: find.byType(TextFormField));
      await tester.ensureVisible(fullscreenField);
      await tester.enterText(fullscreenField, '放大後輸入的描述');
      await tester.pumpAndSettle();
      expect(record.remarksNotifier.value, '放大後輸入的描述');

      await tester.tap(find.byTooltip('縮小'));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
      expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField))
              .controller!
              .text,
          '放大後輸入的描述');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('fullscreen rating shares the same record', (tester) async {
    final record = fixture();
    await pumpCard(tester, record, const Size(1194, 834));
    await tester.tap(find.byTooltip('放大編輯'));
    await tester.pumpAndSettle();
    record.mathPerformanceRatingNotifier.value = 5;
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('縮小'));
    await tester.pumpAndSettle();
    expect(record.mathPerformanceRatingNotifier.value, 5);
  });
}
