import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../model/attachment_ref.dart';
import 'attachment_store.dart';

class AttachmentFailure implements Exception {
  const AttachmentFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Endpoints come from trusted application configuration, never from a saved file URL.
class DriveAttachmentStore implements AttachmentStore {
  DriveAttachmentStore(
      {http.Client? client,
      Future<String?> Function()? token,
      String Function()? account,
      Future<SharedPreferences> Function()? preferences,
      this.uploadSource = 'drive-poc-v1',
      Map<String, Uri>? sources})
      : _client = client ?? http.Client(),
        _token = token ??
            (() async => FirebaseAuth.instance.currentUser?.getIdToken()),
        _account =
            account ?? (() => FirebaseAuth.instance.currentUser?.uid ?? ''),
        _preferences = preferences ?? SharedPreferences.getInstance,
        sources = sources ??
            {
              'drive-poc-v1': Uri.parse(const String.fromEnvironment(
                  'DRIVE_WORKER_URL',
                  defaultValue:
                      'https://yellow-ribbon-drive-poc.jackalopestudio0903.workers.dev'))
            };
  final http.Client _client;
  final Future<String?> Function() _token;
  final String Function() _account;
  final Future<SharedPreferences> Function() _preferences;
  final String uploadSource;
  final Map<String, Uri> sources;
  static const maxBytes = 10 * 1024 * 1024;
  static const supported = {
    'image/png',
    'image/jpeg',
    'image/gif',
    'image/webp',
    'image/bmp',
    'application/pdf',
    'application/msword',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  };
  static final Set<String> _uploads = {};

  Uri _url(String source, String student, String path) {
    final base = sources[source];
    if (base == null ||
        base.scheme != 'https' ||
        base.userInfo.isNotEmpty ||
        base.hasQuery ||
        base.hasFragment) {
      throw const AttachmentFailure('附件來源尚未設定，請聯絡管理員');
    }
    return base.resolve('/v1/students/${Uri.encodeComponent(student)}/$path');
  }

  Future<Map<String, String>> _headers() async {
    final token = await _token();
    if (token == null || token.isEmpty)
      throw const AttachmentFailure('請重新登入後再操作附件');
    return {'Authorization': 'Bearer $token'};
  }

  AttachmentFailure _failure(int status) => AttachmentFailure(switch (status) {
        401 => '登入已失效，請重新登入',
        403 => '目前帳號或學生尚未開放此附件操作',
        404 => '找不到附件，請重新載入確認',
        409 => '附件仍被使用中，請重新載入確認',
        413 => '檔案不可超過 10 MB',
        415 => '檔案格式不支援，請選擇圖片、PDF、Word 或 Excel',
        _ => '附件服務暫時無法連線，原有資料已保留，請稍後再試',
      });
  Future<http.Response> _send(http.Request request) async {
    request.followRedirects = false;
    final response =
        await _client.send(request).timeout(const Duration(seconds: 120));
    final bytes = <int>[];
    await for (final chunk
        in response.stream.timeout(const Duration(seconds: 60))) {
      if (bytes.length + chunk.length > maxBytes)
        throw const AttachmentFailure('附件超過大小限制');
      bytes.addAll(chunk);
    }
    return http.Response.bytes(bytes, response.statusCode,
        headers: response.headers);
  }

  @override
  Future<AttachmentRef> upload(String studentId, String kind, String name,
      String mime, Uint8List bytes) async {
    if (!supported.contains(mime)) throw _failure(415);
    if (bytes.length > maxBytes) throw _failure(413);
    if (bytes.isEmpty || name.isEmpty || name.length > 160)
      throw const AttachmentFailure('檔案是空的或檔名太長');
    final account = _account();
    if (account.isEmpty) throw _failure(401);
    final key = 'drive-upload:$account:$studentId:$kind';
    if (!_uploads.add(key)) throw const AttachmentFailure('附件仍在上傳中，請稍候');
    try {
      final prefs = await _preferences();
      final fingerprint = sha256.convert(bytes).toString();
      final saved = prefs.getString(key);
      if (saved != null) {
        final previous = jsonDecode(saved) as Map<String, dynamic>;
        final request = http.Request(
            'GET',
            _url(previous['source'], studentId,
                'uploads/${previous['operation']}'));
        request.headers.addAll(await _headers());
        final response = await _send(request);
        if (response.statusCode != 200) throw _failure(response.statusCode);
        final ids = (jsonDecode(response.body) as Map)['fileIds'] as List;
        if (ids.length != 1)
          throw const AttachmentFailure('先前上傳結果仍待確認，為避免重複上傳請稍後再試或聯絡管理員');
        if (previous['sha256'] != fingerprint ||
            previous['name'] != name ||
            previous['mime'] != mime) {
          throw const AttachmentFailure('先前檔案已上傳，請先選擇同一檔案完成儲存，再更換檔案');
        }
        final ref = AttachmentRef(
            source: previous['source'],
            studentId: studentId,
            fileId: ids.single as String,
            name: name,
            mime: mime);
        await prefs.remove(key);
        return ref;
      }
      final operation = const Uuid().v4();
      final headers = await _headers();
      if (!await prefs.setString(
          key,
          jsonEncode({
            'source': uploadSource,
            'operation': operation,
            'sha256': fingerprint,
            'name': name,
            'mime': mime
          }))) throw const AttachmentFailure('無法記錄上傳狀態，請稍後再試');
      // Persist recovery information before sending. A lost response never triggers another POST.
      try {
        final request =
            http.Request('POST', _url(uploadSource, studentId, 'files'))
              ..headers.addAll({
                ...headers,
                'Content-Type': mime,
                'X-File-Name': Uri.encodeComponent(name),
                'X-Upload-Id': operation
              })
              ..bodyBytes = bytes;
        final response = await _send(request);
        if (response.statusCode != 201) {
          // Worker reports an explicit upstream rejection separately from a lost response.
          var rejected = false;
          if (response.statusCode == 502 || response.statusCode == 503) {
            try {
              final body = jsonDecode(response.body);
              rejected =
                  body is Map && body['error'] == 'drive_upload_rejected';
            } on FormatException {
              /* Unknown responses retain recovery information. */
            }
          }
          if (rejected ||
              (response.statusCode >= 400 && response.statusCode < 500)) {
            await prefs.remove(key);
            throw _failure(response.statusCode);
          }
          throw const AttachmentFailure('上傳結果尚未確認，請保留原檔，稍後重選同一檔案確認');
        }
        final fileId = (jsonDecode(response.body) as Map)['fileId'];
        if (fileId is! String ||
            !RegExp(r'^[A-Za-z0-9_-]{1,160}$').hasMatch(fileId))
          throw const FormatException();
        final ref = AttachmentRef(
            source: uploadSource,
            studentId: studentId,
            fileId: fileId,
            name: name,
            mime: mime);
        await prefs.remove(key);
        return ref;
      } on AttachmentFailure {
        rethrow;
      } catch (_) {
        throw const AttachmentFailure('上傳結果尚未確認，請保留原檔，稍後重選同一檔案確認');
      }
    } finally {
      _uploads.remove(key);
    }
  }

  @override
  Future<Uint8List> read(AttachmentRef ref) async {
    if (!supported.contains(ref.mime)) throw _failure(415);
    final request = http.Request(
        'GET', _url(ref.source, ref.studentId, 'files/${ref.fileId}'));
    request.headers.addAll(await _headers());
    final response = await _send(request);
    if (response.statusCode != 200) throw _failure(response.statusCode);
    if (response.headers['content-type']?.split(';').first != ref.mime) {
      throw const AttachmentFailure('附件格式與儲存資料不符，請聯絡管理員');
    }
    return response.bodyBytes;
  }

  @override
  Future<bool> remove(AttachmentRef ref) async {
    final request = http.Request(
        'DELETE', _url(ref.source, ref.studentId, 'files/${ref.fileId}'));
    request.headers.addAll(await _headers());
    final response = await _send(request);
    if (response.statusCode == 204 || response.statusCode == 404) return true;
    // A 5xx could mean that Drive applied the trash operation; do not restore a dead link.
    if (response.statusCode >= 500) throw TimeoutException('附件清理結果尚未確認');
    return false;
  }
}
