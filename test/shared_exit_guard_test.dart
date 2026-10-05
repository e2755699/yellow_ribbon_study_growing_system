import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/components/system_page.dart';

class _ExitScenario {
  bool dirty = false;
  bool busy = false;
  int saves = 0;
  Future<bool> Function() save = () async => true;

  Future<void> open(WidgetTester tester, {required bool confirm}) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    final router = GoRouter(initialLocation: '/home', routes: [
      GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('destination'))),
      GoRoute(
          path: '/edit',
          builder: (_, __) => SystemPage(
              scaffoldKey: scaffoldKey,
              title: 'Shared exit policy',
              showSaveConfirmation: confirm,
              hasUnsavedChanges: () => dirty,
              isBusy: () => busy,
              onBeforeExit: () {
                saves++;
                return save();
              },
              child: const Text('draft page'))),
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.push('/edit');
    await tester.pumpAndSettle();
  }

  Future<void> back(WidgetTester tester, {bool system = false}) async {
    if (system) {
      await tester.binding.handlePopRoute();
    } else {
      await tester.tap(find.byTooltip('返回'));
    }
    await tester.pumpAndSettle();
  }
}

void main() {
  for (final confirm in [true, false]) {
    testWidgets(
        'shared clean exit skips both confirmation and save confirm=$confirm',
        (tester) async {
      final scenario = _ExitScenario();
      await scenario.open(tester, confirm: confirm);
      // Callback would fail if called: clean exit must not validate or save.
      scenario.save = () async => false;
      await scenario.back(tester, system: true);
      expect(scenario.saves, 0);
      expect(find.text('保存變更'), findsNothing);
      expect(find.text('destination'), findsOneWidget);
    });

    for (final dirty in [true, false]) {
      testWidgets(
          'shared busy blocks header and system back dirty=$dirty confirm=$confirm',
          (tester) async {
        final scenario = _ExitScenario()..dirty = dirty;
        await scenario.open(tester, confirm: confirm);
        scenario.busy = true; // Latest status without rebuilding the page.
        await scenario.back(tester);
        await scenario.back(tester, system: true);
        expect(scenario.saves, 0);
        expect(find.text('保存變更'), findsNothing);
        expect(find.text('draft page'), findsOneWidget);
        scenario.busy = false;
        scenario.dirty = false;
        await scenario.back(tester);
        expect(find.text('destination'), findsOneWidget);
      });
    }

    testWidgets(
        'shared dirty exit retains failed save and retries confirm=$confirm',
        (tester) async {
      final scenario = _ExitScenario();
      await scenario.open(tester, confirm: confirm);
      scenario.dirty = true; // Controller edits need no parent rebuild.
      scenario.save = () async => false;
      await scenario.back(tester);
      if (confirm) {
        await tester.tap(find.text('保存'));
        await tester.pumpAndSettle();
      } else {
        expect(find.text('保存變更'), findsNothing);
      }
      expect(scenario.saves, 1);
      expect(find.text('draft page'), findsOneWidget);
      scenario.save = () async => true;
      await scenario.back(tester);
      if (confirm) {
        await tester.tap(find.text('保存'));
        await tester.pumpAndSettle();
      }
      expect(scenario.saves, 2);
      expect(find.text('destination'), findsOneWidget);
    });
  }

  testWidgets(
      'operation starting during confirmation cannot be bypassed by discard',
      (tester) async {
    final scenario = _ExitScenario()..dirty = true;
    await scenario.open(tester, confirm: true);
    await scenario.back(tester);
    scenario.busy = true;
    await tester.tap(find.text('不保存'));
    await tester.pumpAndSettle();
    expect(find.text('draft page'), findsOneWidget);
    expect(scenario.saves, 0);
    scenario.busy = false;
    await scenario.back(tester);
    await tester.tap(find.text('不保存'));
    await tester.pumpAndSettle();
    expect(find.text('destination'), findsOneWidget);
    expect(scenario.saves, 0);
  });

  testWidgets(
      'repeated back during a save invokes it once and errors retain the page',
      (tester) async {
    final pending = Completer<bool>();
    final scenario = _ExitScenario()
      ..dirty = true
      ..save = () => pending.future;
    await scenario.open(tester, confirm: false);
    await scenario.back(tester);
    await scenario.back(tester, system: true);
    expect(scenario.saves, 1);
    pending.completeError(StateError('offline'));
    await tester.pumpAndSettle();
    expect(find.text('draft page'), findsOneWidget);
    expect(find.text('保存失敗，請重試'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
