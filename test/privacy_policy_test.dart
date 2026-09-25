import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/domain/theme_defaults.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/privacy_policy.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/privacy/privacy_policy_view.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/login_page/login_page_widget.dart';

void main() {
  for (final dark in [false, true]) {
    for (final size in [
      const Size(1024, 768),
      const Size(768, 1024),
      const Size(1194, 834),
      const Size(834, 1194),
      const Size(507, 768)
    ]) {
      testWidgets('offline policy is readable and returns at $size dark=$dark',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final theme = SystemTheme(defaultDesignThemes().last, dark);
        var returned = false;
        await tester.pumpWidget(MaterialApp(
            theme: theme.materialTheme(),
            home: PrivacyPolicyView(
                updated: privacyPolicyUpdated,
                sections: privacyPolicySections,
                scaffoldKey: GlobalKey<ScaffoldState>(),
                onBack: () => returned = true)));
        await tester.pumpAndSettle();
        final retention = find.textContaining('停止接受服務後保留 1 年');
        await tester.ensureVisible(retention);
        await tester.pumpAndSettle();
        expect(retention.hitTestable(), findsOneWidget);
        await tester.ensureVisible(find.textContaining('e2755699@gmail.com'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.byTooltip('返回'));
        await tester.pumpAndSettle();
        expect(returned, isTrue);
        expect(find.text('是否保存'), findsNothing);
      });
    }
  }
  testWidgets('login policy opens without Firebase and preserves form values',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPageWidget()));
    await tester.enterText(
        find.widgetWithText(TextFormField, '帳號'), 'fixture@example.test');
    await tester.enterText(
        find.widgetWithText(TextFormField, '密碼'), 'fixture-only');
    await tester.tap(find.text('隱私權政策'));
    await tester.pumpAndSettle();
    expect(find.byType(PrivacyPolicyView), findsOneWidget);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text('fixture@example.test'), findsOneWidget);
    expect(find.byType(PrivacyPolicyView), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('policy button supports keyboard and disabled state',
      (tester) async {
    var opened = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Column(children: [
      PrivacyPolicyButton(onPressed: () => opened++),
      const PrivacyPolicyButton(onPressed: null),
    ]))));
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(opened, 1);
    await tester.tap(find.byType(PrivacyPolicyButton).last);
    expect(opened, 1);
  });
}
