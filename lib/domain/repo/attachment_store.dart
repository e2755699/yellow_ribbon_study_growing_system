import 'dart:typed_data';
import '../model/attachment_ref.dart';

abstract class AttachmentStore {
  Future<AttachmentRef> upload(
      String studentId, String kind, String name, String mime, Uint8List bytes);
  Future<Uint8List> read(AttachmentRef ref);
  Future<bool> remove(AttachmentRef ref);
}
