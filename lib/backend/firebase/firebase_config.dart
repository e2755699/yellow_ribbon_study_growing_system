import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Firebase 環境：prod 為 `yellow-ribbon-growing-prod`（Spark），dev 為舊專案
/// `test-o9g27r`。iOS／Android 依 `ios/Runner/GoogleService-Info.plist` 與
/// `android/app/google-services.json` 決定，切換請用
/// `bash tool/use_firebase_env.sh dev|prod`；Web 用
/// `--dart-define=YR_FIREBASE_ENV=dev` 切換，預設 prod。
const firebaseEnvironment =
    String.fromEnvironment('YR_FIREBASE_ENV', defaultValue: 'prod');

const _webOptions = {
  'prod': FirebaseOptions(
      apiKey: "AIzaSyDuDSW13i5jJuEJetKvBsMGErj0jTI3lj4",
      authDomain: "yellow-ribbon-growing-prod.firebaseapp.com",
      projectId: "yellow-ribbon-growing-prod",
      storageBucket: "yellow-ribbon-growing-prod.firebasestorage.app",
      messagingSenderId: "310236133458",
      appId: "1:310236133458:web:ff8b1b0e248cc021bd478b"),
  'dev': FirebaseOptions(
      apiKey: "AIzaSyDntBavv_YGgUHlKLzcSD7LPdRTUi05uck",
      authDomain: "test-o9g27r.firebaseapp.com",
      projectId: "test-o9g27r",
      storageBucket: "test-o9g27r.appspot.com",
      messagingSenderId: "539328215689",
      appId: "1:539328215689:web:05fd5b36d1ff12c068a458"),
};

Future initFirebase() async {
  if (kIsWeb) {
    final options = _webOptions[firebaseEnvironment];
    if (options == null) {
      throw StateError('未知的 YR_FIREBASE_ENV：$firebaseEnvironment');
    }
    await Firebase.initializeApp(options: options);
  } else {
    // 非Web平台也应该提供完整的Firebase配置
    try {
      await Firebase.initializeApp();
      print('Firebase成功初始化 - 移動端 (使用默認配置)');
    } catch (e) {
      print('Firebase初始化錯誤 - 移動端: $e');
    }
  }
}
