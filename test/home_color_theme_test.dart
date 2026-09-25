import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/home_button.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/home_page/home_page_widget.dart';
import 'package:yellow_ribbon_study_growing_system/main/theme/home_color_theme.dart';

double contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  return ((l1 > l2 ? l1 : l2) + 0.05) / ((l1 > l2 ? l2 : l1) + 0.05);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('palette contrast supports the existing large bold card labels', () {
    for (final colors in HomeColorTheme.values) {
      expect(contrast(colors.foreground, colors.card), greaterThanOrEqualTo(3));
      expect(contrast(colors.foreground, colors.hover),
          greaterThan(contrast(colors.foreground, colors.card)));
      expect(contrast(colors.foreground, colors.pressed),
          greaterThan(contrast(colors.foreground, colors.hover)));
      expect(contrast(colors.detail, HomeColorTheme.controlSurface),
          greaterThanOrEqualTo(4.5));
    }
    expect(contrast(HomeColorTheme.controlText, HomeColorTheme.controlSurface),
        greaterThanOrEqualTo(4.5));
  });

  for (final size in [
    const Size(1024, 768),
    const Size(507, 768),
    const Size(375, 667)
  ]) {
    testWidgets('theme selection preserves geometry and persists at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(home: HomePageWidget()));
      await tester.pumpAndSettle();
      final cardRects = [
        for (final item in HomeButton.values)
          tester.getRect(find.byKey(ValueKey(item)))
      ];
      for (final colors in HomeColorTheme.values) {
        await tester.tap(find.byTooltip('切換首頁主題'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(colors.label));
        await tester.pumpAndSettle();
        for (var i = 0; i < HomeButton.values.length; i++) {
          final finder = find.byKey(ValueKey(HomeButton.values[i]));
          expect(tester.getRect(finder), cardRects[i]);
          final button = tester.widget<ElevatedButton>(finder);
          expect(button.style!.backgroundColor!.resolve({}), colors.card);
          expect(button.style!.foregroundColor!.resolve({}), colors.foreground);
          final icon = tester.widget<SvgPicture>(
              find.descendant(of: finder, matching: find.byType(SvgPicture)));
          expect(icon.colorFilter,
              ColorFilter.mode(colors.foreground, BlendMode.srcIn));
        }
        expect(
            (await SharedPreferences.getInstance())
                .getString(HomeColorTheme.preferenceKey),
            colors.name);
        expect(tester.takeException(), isNull);
      }
      // A fresh page reads the last choice, including after reload/navigation.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(const MaterialApp(home: HomePageWidget()));
      await tester.pumpAndSettle();
      final restored = tester.widget<ElevatedButton>(
          find.byKey(const ValueKey(HomeButton.studentInfo)));
      expect(restored.style!.backgroundColor!.resolve({}),
          HomeColorTheme.original.card);
    });
  }

  testWidgets(
      'mouse hover and press darken the rendered card and release restores it',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePageWidget()));
    await tester.pumpAndSettle();
    final finder = find.byKey(const ValueKey(HomeButton.studentInfo));
    final material =
        find.descendant(of: finder, matching: find.byType(Material));
    const colors = HomeColorTheme.caramel;
    expect(tester.widget<Material>(material).color, colors.card);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(finder));
    await tester.pumpAndSettle();
    expect(tester.widget<Material>(material).color, colors.hover);
    await mouse.down(tester.getCenter(finder));
    await tester.pumpAndSettle();
    expect(tester.widget<Material>(material).color, colors.pressed);
    await mouse.cancel();
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    expect(tester.widget<Material>(material).color, colors.card);
    await mouse.removePointer();
  });
}
