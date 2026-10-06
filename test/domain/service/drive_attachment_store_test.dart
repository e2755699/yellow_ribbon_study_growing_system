import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/attachment_ref.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/attachment_store.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/drive_attachment_store.dart';
import 'package:yellow_ribbon_study_growing_system/domain/service/storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final bytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10]);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  DriveAttachmentStore store(Future<http.Response> Function(http.Request) send,
          {String source = 'old', String? auth = 'synthetic-token'}) =>
      DriveAttachmentStore(
          client: MockClient(send),
          token: () async => auth,
          account: () => 'teacher',
          uploadSource: source,
          sources: {
            'old': Uri.parse('https://old.example'),
            'new': Uri.parse('https://new.example')
          });
  test(
      'reference carries provider/source and original filename without credentials',
      () {
    const ref = AttachmentRef(
        source: 'old',
        studentId: 'student',
        fileId: 'file',
        name: '資料 1.pdf',
        mime: 'application/pdf');
    expect(AttachmentRef.parse(ref.encode())!.name, '資料 1.pdf');
    expect(AttachmentRef.displayName(ref.encode()), '資料 1.pdf');
    expect(AttachmentRef.parse('legacy.pdf'), isNull);
    expect(() => AttachmentRef.parse('yrfile:broken'), throwsFormatException);
  });
  test(
      'App upload sends bearer and bytes; known denial can be corrected and retried',
      () async {
    var count = 0;
    final s = store((request) async {
      expect(request.headers['Authorization'], 'Bearer synthetic-token');
      expect(request.followRedirects, isFalse);
      expect(request.bodyBytes, bytes);
      expect(request.url.host, 'old.example');
      expect(request.headers['X-Upload-Id'], isNotEmpty);
      count++;
      return count == 1
          ? http.Response('{}', 403)
          : http.Response('{"fileId":"file"}', 201);
    });
    await expectLater(
        s.upload('student', 'profile', 'one.png', 'image/png', bytes),
        throwsA(isA<AttachmentFailure>()));
    final ref =
        await s.upload('student', 'profile', 'two.png', 'image/png', bytes);
    expect(ref.name, 'two.png');
    expect((await SharedPreferences.getInstance()).getKeys(), isEmpty);
  });
  test(
      'uncertain upload survives service recreation and uses GET recovery instead of another POST',
      () async {
    var posts = 0;
    Future<http.Response> send(http.Request request) async {
      if (request.method == 'POST') {
        posts++;
        return http.Response('{"error":"upload_outcome_unknown"}', 503);
      }
      return http.Response('{"fileIds":["found-file"]}', 200);
    }

    await expectLater(
        store(send).upload('student', 'profile', 'one.png', 'image/png', bytes),
        throwsA(isA<AttachmentFailure>()));
    final ref = await store(send, source: 'new')
        .upload('student', 'profile', 'one.png', 'image/png', bytes);
    expect(posts, 1);
    expect(ref.fileId, 'found-file');
    expect(ref.source, 'old');
  });
  test('explicit Drive rejection allows a corrected upload', () async {
    var calls = 0;
    final s = store((r) async {
      expect(r.method, 'POST');
      return ++calls == 1
          ? http.Response('{ "error": "drive_upload_rejected" }', 502)
          : http.Response('{"fileId":"file"}', 201);
    });
    await expectLater(
        s.upload('student', 'profile', 'one.png', 'image/png', bytes),
        throwsA(isA<AttachmentFailure>()));
    expect(
        (await s.upload('student', 'profile', 'two.png', 'image/png', bytes))
            .name,
        'two.png');
  });
  test('unresolved upload prevents reupload and retains recovery operation',
      () async {
    var posts = 0;
    final s = store((r) async {
      if (r.method == 'POST') {
        posts++;
        return http.Response('{}', 503);
      }
      return http.Response('{"fileIds":[]}', 200);
    });
    for (var i = 0; i < 2; i++) {
      await expectLater(
          s.upload('student', 'profile', 'one.png', 'image/png', bytes),
          throwsA(isA<AttachmentFailure>()));
    }
    expect(posts, 1);
    expect((await SharedPreferences.getInstance()).getKeys(), hasLength(1));
  });
  test(
      'source change preserves old reads, refusal never falls back to public URL',
      () async {
    const ref = AttachmentRef(
        source: 'old',
        studentId: 'student',
        fileId: 'file',
        name: 'a.png',
        mime: 'image/png');
    final s = store((r) async {
      expect(r.url.host, 'old.example');
      return http.Response('{}', 403);
    }, source: 'new');
    await expectLater(s.read(ref), throwsA(isA<AttachmentFailure>()));
  });
  test('missing login and oversized upload never reach HTTP', () async {
    final s = store((_) async => fail('must not call HTTP'), auth: null);
    await expectLater(
        s.upload('student', 'profile', 'a.png', 'image/png', bytes),
        throwsA(isA<AttachmentFailure>()));
    await expectLater(
        s.upload('student', 'profile', 'a.png', 'image/png',
            Uint8List(DriveAttachmentStore.maxBytes + 1)),
        throwsA(isA<AttachmentFailure>()));
  });
  test(
      'existing StorageService routes production avatar/profile and encoded reads to adapter',
      () async {
    final backend = MemoryAttachments();
    final s = StorageService(attachmentStore: backend, useDrive: true);
    final avatar = await s.uploadStudentAvatar('student',
        XFile.fromData(bytes, name: 'avatar.png', mimeType: 'image/png'));
    expect(AttachmentRef.parse(avatar)!.studentId, 'student');
    final profile = await s.uploadStudentProfile(
        'student',
        PlatformFile(
            name: 'report.xlsx',
            size: 8,
            bytes: Uint8List.fromList([80, 75, 3, 4, 0, 0, 0, 0])));
    expect(AttachmentRef.parse(profile)!.mime, contains('spreadsheetml'));
    expect(await s.getAvatarBytes(avatar), backend.bytes);
    expect(await s.getAvatarUrl(avatar), isNull);
    expect(await s.deleteProfileFile(profile!), isTrue);
    expect(backend.kinds, ['avatar', 'profile']);
  });
}

class MemoryAttachments implements AttachmentStore {
  final kinds = <String>[];
  final bytes = Uint8List.fromList([1, 2, 3]);
  @override
  Future<AttachmentRef> upload(String studentId, String kind, String name,
      String mime, Uint8List bytes) async {
    kinds.add(kind);
    return AttachmentRef(
        source: 'old',
        studentId: studentId,
        fileId: 'file-$kind',
        name: name,
        mime: mime);
  }

  @override
  Future<Uint8List> read(AttachmentRef ref) async => bytes;
  @override
  Future<bool> remove(AttachmentRef ref) async => true;
}
