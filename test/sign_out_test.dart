import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/domain/theme_defaults.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/nav/nav.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/login/sign_out_button.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/home_page/home_page_widget.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/login_page/login_page_widget.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
      'sign out prevents duplicate calls and redirects via Auth; private routes stay protected',
      (tester) async {
    final changes = StreamController<bool>.broadcast();
    final auth = AppStateNotifier(
        signedInChanges: changes.stream, initiallySignedIn: true);
    final pending = Completer<void>();
    var calls = 0;
    final router = createRouter(auth, signOut: () async {
      calls++;
      await pending.future;
      changes.add(false);
    });
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.text('登出'));
    await tester.pump();
    expect(find.text('登出中…'), findsOneWidget);
    final button = find.descendant(
        of: find.byType(SignOutButton), matching: find.byType(TextButton));
    expect(tester.widget<TextButton>(button).onPressed, isNull);
    await tester.tap(find.text('登出中…'));
    expect(calls, 1);
    expect(find.byType(HomePageWidget), findsOneWidget);
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(LoginPageWidget), findsOneWidget);
    expect(router.canPop(), isFalse);
    router.go('/studentDetail/edit/private-student');
    await tester.pumpAndSettle();
    expect(router.routerDelegate.currentConfiguration.uri.path, '/');
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    auth.dispose();
    await changes.close();
  });

  testWidgets('failed sign out keeps home, reports failure and permits retry',
      (tester) async {
    var calls = 0;
    await tester
        .pumpWidget(MaterialApp(home: HomePageWidget(onSignOut: () async {
      calls++;
      if (calls == 1) throw StateError('simulated failure');
    })));
    await tester.pumpAndSettle();
    await tester.tap(find.text('登出'));
    await tester.pumpAndSettle();
    expect(find.byType(HomePageWidget), findsOneWidget);
    expect(find.text('登出未完成，請重試'), findsOneWidget);
    await tester.tap(find.text('登出'));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'sign out is keyboard accessible and disabled state cannot activate',
      (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: SignOutButton(onPressed: () => calls++))));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: SignOutButton(onPressed: null))));
    await tester.tap(find.text('登出'));
    expect(calls, 1);
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
          'home toolbar remains reachable and separate from cards $size dark=$dark',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final theme = SystemTheme(defaultDesignThemes().first, dark);
        await tester.pumpWidget(MaterialApp(
            theme: theme.materialTheme(),
            home: HomePageWidget(onSignOut: () async {})));
        await tester.pumpAndSettle();
        expect(find.text('登出').hitTestable(), findsOneWidget);
        expect(tester.getSize(find.byType(SignOutButton)).height,
            greaterThanOrEqualTo(44));
        final toolbar = tester.getRect(find.byType(SignOutButton));
        final firstCard = tester.getRect(find.byType(ElevatedButton).first);
        expect(toolbar.overlaps(firstCard), isFalse);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(MediaQuery(
            data: MediaQueryData(size: size, textScaler: TextScaler.linear(2)),
            child: MaterialApp(
                theme: theme.materialTheme(),
                builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(context)
                        .copyWith(textScaler: TextScaler.linear(2)),
                    child: child!),
                home: HomePageWidget(onSignOut: () async {}))));
        await tester.pumpAndSettle();
        expect(find.text('登出').hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
