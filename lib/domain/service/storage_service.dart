import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 學生頭像存儲路徑
  static const String _avatarFolder = 'avatars';

  // 上傳頭像圖片
  Future<String?> uploadStudentAvatar(String studentId, XFile file) async {
    try {
      // 文件擴展名
      final extension = path.extension(file.path);
      // 生成唯一文件名
      final fileName =
          '${studentId}_${DateTime.now().millisecondsSinceEpoch}$extension';
      // 存儲路徑
      final storageRef = _storage.ref().child('$_avatarFolder/$fileName');

      UploadTask uploadTask;

      if (kIsWeb) {
        // Web平台上傳
        uploadTask = storageRef.putData(await file.readAsBytes());
      } else {
        // 移動端上傳
        uploadTask = storageRef.putFile(File(file.path));
      }

      // 等待上傳完成
      await uploadTask;

      // 返回文件名
      return fileName;
    } catch (e) {
      print('上傳頭像失敗: $e');
      return null;
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
      return false;
    }
  }
}
