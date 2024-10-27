import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
            apiKey: "AIzaSyDntBavv_YGgUHlKLzcSD7LPdRTUi05uck",
            authDomain: "test-o9g27r.firebaseapp.com",
            projectId: "test-o9g27r",
            storageBucket: "test-o9g27r.appspot.com",
            messagingSenderId: "539328215689",
            appId: "1:539328215689:web:05fd5b36d1ff12c068a458"));
  } else {
    await Firebase.initializeApp();
  }
}
