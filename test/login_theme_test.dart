import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/application/design_system_store.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/data/memory_design_system_repository.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/domain/theme_defaults.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/login/login_submit_button.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/privacy/privacy_policy_view.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/login_page/login_page_widget.dart';

void main() {
  for (final dark in [false, true]) {
    testWidgets('login follows unpublished and custom themes, dark=$dark',
        (tester) async {
      SharedPreferences.setMockInitialValues({'home_color_theme': 'olive'});
      final repository = MemoryDesignSystemRepository();
      final store = DesignSystemStore(repository);
      GetIt.I.registerSingleton<DesignSystemStore>(store);
      addTearDown(() async {
        await GetIt.I.unregister<DesignSystemStore>();
        store.dispose();
        await repository.dispose();
      });
      await store.start();
      await tester.pumpWidget(MaterialApp(
          theme:
              ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
          home: const LoginPageWidget()));
      await tester.pumpAndSettle();
      expect(store.hasPublishedActive, isFalse);
      expect(store.activeId, 'olive');
      final account = find.widgetWithText(TextFormField, '帳號');
      await tester.enterText(account, 'preview@example.org');

      void checkTheme() {
        final ds = SystemTheme(store.active, dark);
        final button =
            tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.style!.backgroundColor!.resolve({}), ds.primary);
        expect(button.style!.foregroundColor!.resolve({}), ds.onPrimary);
        expect(button.style!.textStyle!.resolve({})!.fontSize,
            ds.metric('buttonSize'));
        expect(button.style!.padding!.resolve({}),
            EdgeInsets.all(ds.metric('spaceMedium')));
        expect(
            (button.style!.shape!.resolve({}) as RoundedRectangleBorder)
                .borderRadius,
            BorderRadius.circular(ds.metric('radiusSmall')));
        for (final type in [
          LoginSubmitButton,
          PrivacyPolicyButton,
          TextFormField
        ]) {
          expect(
              SystemTheme.of(tester.element(find.byType(type).first))
                  .definition
                  .id,
              store.active.id);
        }
      }

      checkTheme();
      store.select('teal');
      await tester.pumpAndSettle();
      checkTheme();
      final custom = store.active
          .duplicate(id: 'login-custom', name: '登入測試主題')
          .withColor(dark, 'primary', '#235F43')
          .withColor(dark, 'onPrimary', '#FFF3CE')
          .copyWith(metrics: {
        ...store.active.metrics,
        'buttonSize': 26,
        'spaceMedium': 20,
        'radiusSmall': 8
      });
      store.acceptPublished(custom);
      store.select(custom.id);
      await tester.pumpAndSettle();
      checkTheme();
      expect(tester.widget<TextFormField>(account).controller!.text,
          'preview@example.org');
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets('login button supports keyboard and blocks repeat submission',
      (tester) async {
    final ds = SystemTheme(defaultDesignThemes().first, false);
    var calls = 0;
    Future<void> show({bool submitting = false, bool disabled = false}) async {
      await tester.pumpWidget(MaterialApp(
          theme: ds.materialTheme(),
          home: Scaffold(
              body: LoginSubmitButton(
                  submitting: submitting,
                  onPressed: disabled ? null : () => calls++))));
      await tester.pump();
    }

    await show();
    await tester.tap(find.text('登入'));
    expect(calls, 1);
    final context = tester.element(find.byType(ElevatedButton));
    Focus.of(tester.element(find.text('登入'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(calls, 2);
    expect(SystemTheme.of(context).definition.id, ds.definition.id);
    await show(submitting: true);
    await tester.tap(find.text('登入中…'));
    expect(calls, 2);
    final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
    expect(button.onPressed, isNull);
    expect(button.style!.backgroundColor!.resolve({WidgetState.disabled}),
        isNot(ds.primary));
    await show(disabled: true);
    await tester.tap(find.text('登入'));
    expect(calls, 2);
  });
}
