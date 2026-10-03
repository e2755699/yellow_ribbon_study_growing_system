import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class DraftStore {
  Future<Map<String, dynamic>?> read(String uid, String scope);
  Future<void> write(String uid, String scope, Map<String, dynamic>? draft);
}

class MemoryDraftStore implements DraftStore {
  final _values = <String, String>{};
  @override
  Future<Map<String, dynamic>?> read(String uid, String scope) async {
    final value = _values[jsonEncode([uid, scope])];
    return value == null ? null : jsonDecode(value) as Map<String, dynamic>;
  }

  @override
  Future<void> write(
      String uid, String scope, Map<String, dynamic>? draft) async {
    final key = jsonEncode([uid, scope]);
    if (draft == null) {
      _values.remove(key);
    } else {
      _values[key] = jsonEncode(draft);
    }
  }
}

class SecureDraftStore implements DraftStore {
  final FlutterSecureStorage storage;
  SecureDraftStore({FlutterSecureStorage? storage})
      : storage = storage ??
            const FlutterSecureStorage(
                iOptions: IOSOptions(synchronizable: false));
  String _key(String uid, String scope) =>
      'roster_draft_v2_${base64Url.encode(utf8.encode(jsonEncode([
            uid,
            scope
          ])))}';
  @override
  Future<Map<String, dynamic>?> read(String uid, String scope) async {
    final raw = await storage.read(key: _key(uid, scope));
    if (raw == null) return null;
    final envelope = jsonDecode(raw) as Map<String, dynamic>;
    if (envelope['uid'] != uid || envelope['schemaVersion'] != 2) {
      throw StateError('草稿版本或帳號不符，請勿覆寫');
    }
    return Map<String, dynamic>.from(envelope['draft'] as Map);
  }

  @override
  Future<void> write(
      String uid, String scope, Map<String, dynamic>? draft) async {
    final key = _key(uid, scope);
    if (draft == null) {
      await storage.delete(key: key);
    } else {
      await storage.write(
          key: key,
          value: jsonEncode({
            'schemaVersion': 2,
            'uid': uid,
            'savedAt': DateTime.now().toUtc().toIso8601String(),
            'draft': draft,
          }));
    }
  }
}

DraftStore platformDraftStore() =>
    kIsWeb ? MemoryDraftStore() : SecureDraftStore();
