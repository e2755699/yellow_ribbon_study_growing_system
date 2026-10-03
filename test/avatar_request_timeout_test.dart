import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/avatar/avatar_network_image_native.dart';

class _WaitingHttpClient extends Fake implements HttpClient {
  @override
  bool autoUncompress = false;
  @override
  Future<HttpClientRequest> getUrl(Uri url) =>
      Completer<HttpClientRequest>().future;
}

void main() {
  testWidgets('avatar switches to existing retry fallback after 60 seconds',
      (tester) async {
    final original = debugNetworkImageHttpClientProvider;
    debugNetworkImageHttpClientProvider = () => _WaitingHttpClient();
    addTearDown(() {
      debugNetworkImageHttpClientProvider = original;
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    });
    try {
      await tester.pumpWidget(MaterialApp(
          home: AvatarNetworkImage(
        url: 'https://example.invalid/net-a1-avatar.png',
        size: 100,
        onError: () => const Text('重試頭像'),
      )));
      await tester.pump(const Duration(seconds: 59));
      expect(find.text('重試頭像'), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('重試頭像'), findsOneWidget);
    } finally {
      debugNetworkImageHttpClientProvider = original;
    }
  });
}
