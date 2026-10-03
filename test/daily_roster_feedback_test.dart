import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/domain/theme_defaults.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/daily_roster_cubit/daily_roster_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/service/daily_roster_service.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/draft_store.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/memory_roster_repository.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/roster/roster_models.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/roster_repository.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/daily_roster_page.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets(
        'failed save alerts and keyboard retry succeeds in ${dark ? "Dark" : "Light"}',
        (tester) async {
      tester.view.physicalSize = const Size(507, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final date = BusinessDate('2026-10-02');
      final repo = MemoryRosterRepository(
          access: RosterAccess('synthetic', 'manager', ['a']),
          sites: const [
            ClassSite('a', '合成據點')
          ],
          students: const [
            StudentSummary('s', '合成小禾')
          ],
          enrollments: [
            Enrollment('e',
                studentId: 's',
                locationId: 'a',
                startDate: date,
                endDateExclusive: BusinessDate('9999-12-31'))
          ]);
      final cubit = DailyRosterCubit(
          kind: 'attendance',
          service: DailyRosterService(repo),
          draftStore: MemoryDraftStore(),
          date: date)
        ..start();
      await tester.pumpWidget(MaterialApp(
          theme: SystemTheme(defaultDesignThemes().first, dark).materialTheme(),
          home: BlocProvider.value(
              value: cubit, child: const DailyRosterPage())));
      await tester.pumpAndSettle();
      cubit.edit('s', 'status', 'attend');
      repo.failStudents.add('s');
      await tester.pumpAndSettle();
      await tester.tap(find.text('儲存修改'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
          find.descendant(
              of: find.byType(AlertDialog),
              matching: find.textContaining('整批儲存失敗')),
          findsOneWidget);
      expect(cubit.state.drafts, isNotEmpty);
      await tester.tap(find.text('返回檢查'));
      await tester.pumpAndSettle();
      expect(find.text('重試儲存'), findsOneWidget);
      expect(find.text('核對後保留我的修改'), findsNothing);
      final discard =
          tester.widget<TextButton>(find.widgetWithText(TextButton, '捨棄本筆修改'));
      expect(discard.onPressed, isNotNull);
      repo.failStudents.clear();
      final retryElement =
          tester.element(find.widgetWithText(ElevatedButton, '重試儲存'));
      // Traverse until the enabled save button receives keyboard focus.
      var retryHasFocus = false;
      for (var i = 0; i < 20; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();
        FocusManager.instance.primaryFocus?.context
            ?.visitAncestorElements((element) {
          if (identical(element, retryElement)) retryHasFocus = true;
          return !retryHasFocus;
        });
        if (retryHasFocus) break;
      }
      expect(retryHasFocus, isTrue,
          reason: 'Tab must reach the retry button before Enter submits.');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(cubit.state.drafts, isEmpty);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.textContaining('已確認儲存 1 筆修改'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      // Closing the combined subscription schedules asynchronous stream cleanup.
      // Allow that cleanup to run outside the widget test's fake clock.
      await tester.runAsync(() async {
        await cubit.close();
        await repo.dispose();
      });
    });
  }
}
