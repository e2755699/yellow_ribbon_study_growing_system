import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../repo/students_repo.dart';
import 'storage_service.dart';

class AttachmentResult {
  const AttachmentResult(this.fileName, {this.cleanupFailed = false});
  final String fileName;
  final bool cleanupFailed;
}

class StudentAttachmentService {
  StudentAttachmentService({required this.students, required this.storage});
  final StudentsRepo students;
  final StorageService storage;

  Future<AttachmentResult> replaceProfile(
          String id, String? previous, PlatformFile file) =>
      _replace(
        previous,
        upload: () => storage.uploadStudentProfile(id, file),
        persist: (name) => students.updateProfileFile(id, name),
        remove: storage.deleteProfileFile,
      );

  Future<AttachmentResult> replaceAvatar(
          String id, String? previous, XFile file) =>
      _replace(
        previous,
        upload: () => storage.uploadStudentAvatar(id, file),
        persist: (name) => students.updateAvatar(id, name),
        remove: storage.deleteAvatar,
      );

  Future<bool> _removeSafely(
      Future<bool> Function(String) remove, String name) async {
    try {
      return await remove(name);
    } catch (_) {
      return false;
    }
  }

  Future<AttachmentResult> _replace(
    String? previous, {
    required Future<String?> Function() upload,
    required Future<void> Function(String) persist,
    required Future<bool> Function(String) remove,
  }) async {
    final next = await upload();
    if (next == null || next.isEmpty) throw StateError('上傳失敗，原檔案已保留');
    try {
      await persist(next);
    } on TimeoutException {
      // The queued Firestore update may still succeed. Keep both files.
      throw StateError('檔案資料儲存結果尚未確認，原檔與新檔均保留；請重新載入確認，勿重複上傳。');
    } catch (_) {
      final cleaned = await _removeSafely(remove, next);
      throw StateError(
          cleaned ? '檔案資料儲存失敗，原檔案已保留' : '檔案資料儲存失敗，原檔案已保留；新上傳檔案待清理');
    }
    final needsCleanup =
        previous != null && previous.isNotEmpty && previous != next;
    final cleaned = !needsCleanup || await _removeSafely(remove, previous);
    return AttachmentResult(next, cleanupFailed: !cleaned);
  }

  Future<void> deleteProfile(String id, String fileName) async {
    // Remove the reference first, so a failed Firestore write never destroys a file.
    await students.updateProfileFile(id, null);
    try {
      if (await storage.deleteProfileFile(fileName)) return;
    } on TimeoutException {
      // A late successful deletion would make restoring this link incorrect.
      throw StateError('檔案刪除結果尚未確認，請重新載入並核對；暫不復原資料連結。');
    } catch (_) {
      // Definite failure follows the existing link rollback below.
    }
    try {
      await students.updateProfileFile(id, fileName);
    } catch (_) {
      throw StateError('刪除未完成，檔案仍保留，但資料連結復原失敗；請重新載入並聯絡管理者');
    }
    throw StateError('刪除失敗，原檔案與資料連結已保留，請重試');
  }
}
