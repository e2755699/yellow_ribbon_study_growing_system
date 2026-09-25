import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../tool/store_preview.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('capture actual iPad production components with synthetic data',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft]);
    for (final scene in ['login', 'home', 'directory', 'profile']) {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(storePreview(scene));
      // pumpAndSettle alone can finish before asset I/O/decoding schedules a
      // frame. Await the actual raster/vector assets before taking store photos.
      final context = tester.element(find.byType(MaterialApp));
      await tester.runAsync(() async {
        for (final asset in ['login_bg.webp', 'login_avatar.webp']) {
          await precacheImage(AssetImage('assets/images/$asset'), context);
        }
        for (final icon in ['students', 'everyday', 'star', 'school']) {
          await SvgAssetLoader('assets/images/$icon.svg').loadBytes(context);
        }
      });
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('ipad-$scene');
    }
  });
}
