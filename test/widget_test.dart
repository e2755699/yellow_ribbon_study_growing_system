import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/home_button.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/nav/nav.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/home_page/home_page_widget.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/login_page/login_page_widget.dart';

void main() {
  testWidgets(
      'login validates required fields and malformed email without Firebase',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPageWidget()));
    await tester.tap(find.text('登入'));
    await tester.pump();
    expect(find.text('請輸入帳號'), findsOneWidget);
    expect(find.text('請輸入密碼'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextFormField, '帳號'), 'invalid-email');
    await tester.enterText(
        find.widgetWithText(TextFormField, '密碼'), 'test-only');
    await tester.tap(find.text('登入'));
    await tester.pump();
    expect(find.text('請輸入有效的 Email'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(1024, 768),
    const Size(768, 1024),
    const Size(1194, 834),
    const Size(834, 1194),
    const Size(507, 768),
    const Size(375, 667)
  ]) {
    testWidgets('home remains scrollable with every action reachable at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: HomePageWidget()));
      await tester.pumpAndSettle();
      expect(find.text('按鈕展示'), findsNothing);
      expect(HomeButton.values.length, 4);
      for (final title in ['學生資料', '每日出席', '每日表現', '成長報告']) {
        expect(find.text(title), findsOneWidget);
      }
      final first =
          tester.getRect(find.byKey(const ValueKey(HomeButton.studentInfo)));
      final second = tester
          .getRect(find.byKey(const ValueKey(HomeButton.dailyAttendance)));
      final third = tester
          .getRect(find.byKey(const ValueKey(HomeButton.dailyPerformance)));
      if (size.width >= 680) {
        expect(first.top, second.top);
        expect(first.width, second.width);
        expect(first.left, third.left);
        expect(third.top, greaterThan(first.bottom));
      } else {
        expect(first.left, second.left);
        expect(second.top, greaterThan(first.bottom));
      }
      for (final item in HomeButton.values) {
        final target = find.byKey(ValueKey(item));
        await tester.ensureVisible(target);
        await tester.pumpAndSettle();
        expect(target.hitTestable(), findsOneWidget);
        expect(tester.getSize(target).height, greaterThanOrEqualTo(44));
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('login fits keyboard and split-screen at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(const MaterialApp(home: LoginPageWidget()));
      await tester.ensureVisible(find.text('登入'));
      await tester.pumpAndSettle();
      expect(find.text('登入').hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'protected deep links redirect; login and logout refresh navigation',
      (tester) async {
    final changes = StreamController<bool>.broadcast();
    final auth = AppStateNotifier(signedInChanges: changes.stream);
    final router = createRouter(auth);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/home');
    await tester.pumpAndSettle();
    expect(find.byType(LoginPageWidget), findsOneWidget);
    expect(router.routerDelegate.currentConfiguration.uri.path, '/');
    router.go('/studentDetail/edit/private-student');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/');
    router.go('/');
    await tester.pumpAndSettle();
    changes.add(true);
    await tester.pumpAndSettle();
    expect(find.byType(HomePageWidget), findsOneWidget);
    router.go('/buttonShowcase');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
    expect(find.text('按鈕展示'), findsNothing);
    changes.add(false);
    await tester.pumpAndSettle();
    expect(find.byType(LoginPageWidget), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    auth.dispose();
    await changes.close();
  });
}
