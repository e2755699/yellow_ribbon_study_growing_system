import 'dart:convert';

/// A stable reference, never a public URL or a credential. Source survives switching upload targets.
class AttachmentRef {
  const AttachmentRef(
      {required this.source,
      required this.studentId,
      required this.fileId,
      required this.name,
      required this.mime});
  final String source, studentId, fileId, name, mime;
  static const prefix = 'yrfile:';
  String encode() => '$prefix${Uri.encodeComponent(jsonEncode({
            'v': 1,
            'provider': 'googleDrive',
            'source': source,
            'studentId': studentId,
            'fileId': fileId,
            'name': name,
            'mime': mime,
          }))}';
  static AttachmentRef? parse(String? value) {
    if (value == null || !value.startsWith(prefix)) return null;
    try {
      final data =
          jsonDecode(Uri.decodeComponent(value.substring(prefix.length)));
      if (data is! Map || data['v'] != 1 || data['provider'] != 'googleDrive')
        throw const FormatException();
      for (final key in ['source', 'studentId', 'fileId']) {
        if (data[key] is! String ||
            !RegExp(r'^[A-Za-z0-9_-]{1,160}$').hasMatch(data[key]))
          throw const FormatException();
      }
      if (data['name'] is! String || data['mime'] is! String)
        throw const FormatException();
      return AttachmentRef(
          source: data['source'],
          studentId: data['studentId'],
          fileId: data['fileId'],
          name: data['name'],
          mime: data['mime']);
    } catch (_) {
      throw const FormatException('附件參照格式不正確，請聯絡管理員');
    }
  }

  static String displayName(String value) {
    try {
      return parse(value)?.name ?? value;
    } catch (_) {
      return '附件';
    }
  }
}
