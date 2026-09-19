import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'avatar_image_data.dart';

class StorageService {
  late final FirebaseStorage _storage = FirebaseStorage.instance;
  late final FirebaseAuth _auth = FirebaseAuth.instance;

  // 學生頭像存儲路徑
  static const String _avatarFolder = 'avatars';

  // 學生個人檔案存儲路徑
  static const String _profileFolder = 'profiles';

  // 上傳頭像圖片
  Future<String?> uploadStudentAvatar(String studentId, XFile file) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw StateError('登入已失效，請重新登入後更換頭像');
      }
      final image = await AvatarImageData.fromFile(file);
      final fileName =
          '${studentId}_${DateTime.now().microsecondsSinceEpoch}${image.extension}';
      final storageRef = _storage.ref().child('$_avatarFolder/$fileName');
      final metadata = SettableMetadata(
        contentType: image.contentType,
        customMetadata: {
          'uploadedBy': currentUser.uid,
          'studentId': studentId,
        },
      );
      await storageRef.putData(image.bytes, metadata);
      return fileName;
    } on FirebaseException catch (error) {
      debugPrint('頭像上傳失敗: ${error.code}');
      throw StateError(error.code == 'unauthorized'
          ? '沒有上傳頭像的權限，請重新登入後再試'
          : '頭像上傳失敗，請確認網路後再試');
    }
  }

  // 獲取頭像下載URL
  Future<String?> getAvatarUrl(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return null;

    try {
      return await _storage
          .ref()
          .child('$_avatarFolder/$fileName')
          .getDownloadURL();
    } catch (e) {
      print('獲取頭像URL失敗: $e');
      return null;
    }
  }

  // 刪除頭像
  Future<bool> deleteAvatar(String fileName) async {
    try {
      await _storage.ref().child('$_avatarFolder/$fileName').delete();
      return true;
    } catch (e) {
      print('刪除頭像失敗: $e');
      if (e is FirebaseException && e.code == 'object-not-found') return true;
      return false;
    }
  }

  // 上傳學生個人檔案
  Future<String?> uploadStudentProfile(
      String studentId, PlatformFile file) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('用戶未登錄，無法上傳個人檔案');
        return null;
      }

      final ext = file.extension != null ? '.${file.extension}' : '';
      final fileName =
          '${studentId}_${DateTime.now().millisecondsSinceEpoch}$ext';
      final storageRef = _storage.ref().child('$_profileFolder/$fileName');

      final metadata = SettableMetadata(
        customMetadata: {
          'uploadedBy': currentUser.uid,
          'studentId': studentId,
          'originalName': file.name,
        },
      );

      UploadTask uploadTask;

      if (kIsWeb) {
        final bytes = file.bytes!;
        uploadTask = storageRef.putData(bytes, metadata);
      } else {
        final fileObj = File(file.path!);
        uploadTask = storageRef.putFile(fileObj, metadata);
      }

      final snapshot = await uploadTask;
      print('個人檔案上傳成功，狀態: ${snapshot.state}');

      return fileName;
    } catch (e) {
      print('上傳個人檔案失敗: $e');
      return null;
    }
  }

  // 取得個人檔案下載 URL
  Future<String?> getProfileFileUrl(String? fileName) async {
    if (fileName == null || fileName.isEmpty) return null;
    try {
      return await _storage
          .ref()
          .child('$_profileFolder/$fileName')
          .getDownloadURL();
    } catch (e) {
      print('取得個人檔案 URL 失敗: $e');
      return null;
    }
  }

  // 刪除個人檔案
  Future<bool> deleteProfileFile(String fileName) async {
    try {
      await _storage.ref().child('$_profileFolder/$fileName').delete();
      return true;
    } catch (e) {
      print('刪除個人檔案失敗: $e');
      if (e is FirebaseException && e.code == 'object-not-found') return true;
      return false;
    }
  }
}
