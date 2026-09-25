import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
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
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await binding.takeScreenshot('ipad-$scene');
    }
  });
}
