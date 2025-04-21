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
        final bytes = await file.readAsBytes();
        print('Web平台上傳 - 文件大小: ${bytes.length} bytes');
        uploadTask = storageRef.putData(bytes);
      } else {
        // 移動端上傳
        final fileObj = File(file.path);
        print(
            '移動端上傳 - 文件: ${fileObj.path}, 文件大小: ${await fileObj.length()} bytes');
        uploadTask = storageRef.putFile(fileObj);
      }

      // 監聽上傳進度和錯誤
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('上傳進度: ${(progress * 100).toStringAsFixed(2)}%');
      }, onError: (e) {
        print('上傳監聽錯誤: $e');
        if (e is FirebaseException) {
          print('Firebase錯誤碼: ${e.code}, 消息: ${e.message}');
        }
      });

      // 等待上傳完成
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('上傳成功，文件URL: $downloadUrl');

      // 返回文件名
      return fileName;
    } catch (e) {
      print('上傳頭像失敗詳細錯誤: $e');
      if (e is FirebaseException) {
        print('Firebase錯誤碼: ${e.code}, 消息: ${e.message}');

        // 特別處理權限錯誤
        if (e.code == 'unauthorized' || e.code == 'permission-denied') {
          print('權限被拒絕。請確認Firebase Storage規則是否正確配置。');
        }
      }
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
