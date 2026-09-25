import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/performance_rating.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_performance/student_daily_performance_info.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/daily_performance_page/daily_performance_page_widget.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_attendance/student_daily_attendance_info.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yb_layout.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/daily_attendance_page/daily_attendance_page_widget.dart';

void main() {
  testWidgets('performance card fits split view and retains edited remarks',
      (tester) async {
    final record = StudentDailyPerformanceRecord('fixture', '測試學生的較長姓名測試學生',
        ClassLocation.values.first, PerformanceRating.average);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SingleChildScrollView(
                child: Center(
                    child: SizedBox(
      width: 340,
      child: DailyPerformanceRecordCard(record),
    ))))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), '今日專心上課');
    await tester.pumpAndSettle();
    expect(record.remarksNotifier.value, '今日專心上課');
    expect(
        tester
                .widget<TextFormField>(find.byType(TextFormField))
                .controller
                ?.text ??
            tester
                .widget<TextFormField>(find.byType(TextFormField))
                .initialValue,
        '今日專心上課');
    expect(tester.takeException(), isNull);
  });
  for (final confirm in [false, true]) {
    testWidgets('failed save keeps draft page (confirmation: $confirm)',
        (tester) async {
      var saves = 0;
      var saveSucceeds = false;
      final scaffoldKey = GlobalKey<ScaffoldState>();
      final router = GoRouter(initialLocation: '/edit', routes: [
        GoRoute(
            path: '/home',
            builder: (_, __) => const Scaffold(body: Text('home destination'))),
        GoRoute(
            path: '/edit',
            builder: (_, __) => YbLayout(
                  scaffoldKey: scaffoldKey,
                  title: '編輯',
                  showSaveConfirmation: confirm,
                  onBeforeExit: () async {
                    saves++;
                    return saveSucceeds;
                  },
                  child: const Text('unsaved draft'),
                )),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      if (confirm) {
        await tester.tap(find.byTooltip('返回'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('取消'));
        await tester.pumpAndSettle();
        expect(saves, 0);
      }
      await tester.tap(find.byTooltip('返回'));
      await tester.pumpAndSettle();
      if (confirm) {
        await tester.tap(find.text('保存'));
        await tester.pumpAndSettle();
      }
      expect(find.text('unsaved draft'), findsOneWidget);
      expect(saves, 1);
      saveSucceeds = true;
      await tester.tap(find.byTooltip('返回'));
      await tester.pumpAndSettle();
      if (confirm) {
        await tester.tap(find.text('保存'));
        await tester.pumpAndSettle();
      }
      expect(find.text('home destination'), findsOneWidget);
      expect(saves, 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('attendance leave reason and checkbox work in narrow card',
      (tester) async {
    final record = StudentDailyAttendanceRecord('fixture', '測試學生的較長姓名',
        ClassLocation.values.first, AttendanceStatus.leave);
    addTearDown(record.attendanceStatusNotifier.dispose);
    addTearDown(record.leaveReasonNotifier.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Center(
                child: SizedBox(
      width: 300,
      height: 230,
      child: AttendanceRecordCard(record,
          attendStatusNotifier: record.attendanceStatusNotifier),
    )))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '家庭活動');
    expect(record.leaveReasonNotifier.value, '家庭活動');
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(record.attendanceStatusNotifier.value, AttendanceStatus.attend);
    expect(find.byType(TextFormField), findsNothing);
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();
    expect(record.attendanceStatusNotifier.value, AttendanceStatus.absent);
    expect(tester.takeException(), isNull);
  });
}
