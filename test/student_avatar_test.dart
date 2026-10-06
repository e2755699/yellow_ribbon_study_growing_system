import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:yellow_ribbon_study_growing_system/domain/model/attachment_ref.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/domain/service/storage_service.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/avatar/student_avatar.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/avatar/avatar_network_image.dart';

class AvatarStorage implements StorageService {
  final requests = <String, Completer<String?>>{};
  int calls = 0;
  final byteRequests = <String, Completer<Uint8List?>>{};
  @override
  Future<Uint8List?> getAvatarBytes(String? name) =>
      (byteRequests[name!] = Completer<Uint8List?>()).future;
  @override
  Future<String?> getAvatarUrl(String? name) {
    calls++;
    return (requests[name!] = Completer<String?>()).future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget host(AvatarStorage storage, String? name) => MaterialApp(
        home: Scaffold(
            body: StudentAvatar(avatarFileName: name, storageService: storage)),
      );

  testWidgets('a slow old lookup cannot overwrite the replacement avatar',
      (tester) async {
    final storage = AvatarStorage();
    await tester.pumpWidget(host(storage, 'old.jpg'));
    await tester.pumpWidget(host(storage, 'new.jpg'));
    storage.requests['new.jpg']!.complete('https://example.invalid/new.jpg');
    await tester.pump();
    storage.requests['old.jpg']!.complete(null);
    await tester.pump();
    expect(
        tester.widget<AvatarNetworkImage>(find.byType(AvatarNetworkImage)).url,
        'https://example.invalid/new.jpg');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'protected Drive image uses authenticated bytes and ignores an old completion',
      (tester) async {
    final storage = AvatarStorage();
    String ref(String id) => AttachmentRef(
            source: 'test',
            studentId: 'student',
            fileId: id,
            name: 'avatar.gif',
            mime: 'image/gif')
        .encode();
    await tester.pumpWidget(host(storage, ref('old')));
    await tester.pumpWidget(host(storage, ref('new')));
    storage.byteRequests[ref('new')]!.complete(base64Decode(
        'R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7'));
    await tester.pump();
    storage.byteRequests[ref('old')]!.complete(null);
    await tester.pump();
    expect(storage.calls, 0);
    expect(find.byType(AvatarNetworkImage), findsNothing);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.widget<Image>(find.byType(Image)).image, isA<MemoryImage>());
  });

  testWidgets('clearing an avatar invalidates the pending download lookup',
      (tester) async {
    final storage = AvatarStorage();
    await tester.pumpWidget(host(storage, 'old.jpg'));
    await tester.pumpWidget(host(storage, null));
    storage.requests['old.jpg']!.complete('https://example.invalid/old.jpg');
    await tester.pump();
    expect(find.byType(AvatarNetworkImage), findsNothing);
    expect(find.byIcon(Icons.person), findsOneWidget);
  });

  testWidgets('failed avatar lookup exposes a working retry', (tester) async {
    final storage = AvatarStorage();
    await tester.pumpWidget(host(storage, 'photo.jpg'));
    storage.requests['photo.jpg']!.complete(null);
    await tester.pump();
    expect(find.text('重新載入'), findsOneWidget);
    await tester.tap(find.text('重新載入'));
    await tester.pump();
    expect(storage.calls, 2);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    storage.requests['photo.jpg']!.complete(null);
    await tester.pump();
  });
}
