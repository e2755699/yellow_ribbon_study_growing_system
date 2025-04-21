import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 學生頭像存儲路徑
  static const String _avatarFolder = 'avatars';

  // 上傳頭像圖片
  Future<String?> uploadStudentAvatar(String studentId, XFile file) async {
    try {
      // 檢查用戶是否已登錄
      final currentUser = _auth.currentUser;
      print('當前用戶狀態: ${currentUser != null ? "已登錄" : "未登錄"}');
      if (currentUser != null) {
        print('用戶ID: ${currentUser.uid}');
        print('用戶郵箱: ${currentUser.email}');
      }

      if (currentUser == null) {
        print('用戶未登錄，無法上傳文件');
        return null;
      }

      // 文件擴展名
      final extension = path.extension(file.path);
      print('文件擴展名: $extension');

      // 生成唯一文件名
      final fileName =
          '${studentId}_${DateTime.now().millisecondsSinceEpoch}$extension';
      print('生成的文件名: $fileName');

      // 存儲路徑
      final storageRef = _storage.ref().child('$_avatarFolder/$fileName');
      print('存儲路徑: $_avatarFolder/$fileName');

      // 設置元數據，包括內容類型
      final metadata = SettableMetadata(
        contentType: 'image/${extension.replaceAll('.', '')}',
        customMetadata: {
          'uploadedBy': currentUser.uid,
          'studentId': studentId,
        },
      );

      UploadTask uploadTask;

      if (kIsWeb) {
        // Web平台上傳
        final bytes = await file.readAsBytes();
        print('Web平台上傳 - 文件大小: ${bytes.length} bytes');
        uploadTask = storageRef.putData(bytes, metadata);
      } else {
        // 移動端上傳
        final fileObj = File(file.path);
        print(
            '移動端上傳 - 文件: ${fileObj.path}, 文件大小: ${await fileObj.length()} bytes');
        uploadTask = storageRef.putFile(fileObj, metadata);
      }

      // 監聽上傳進度和錯誤
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('上傳進度: ${(progress * 100).toStringAsFixed(2)}%');
      }, onError: (e) {
        print('上傳監聽錯誤: $e');
        if (e is FirebaseException) {
          print('Firebase錯誤碼: ${e.code}, 消息: ${e.message}');
          print('錯誤詳情: ${e.toString()}');
        }
      });

      // 等待上傳完成
      final snapshot = await uploadTask;
      print('上傳任務完成，狀態: ${snapshot.state}');

      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('上傳成功，文件URL: $downloadUrl');

      // 返回文件名
      return fileName;
    } catch (e) {
      print('上傳頭像失敗詳細錯誤: $e');
      if (e is FirebaseException) {
        print('Firebase錯誤碼: ${e.code}, 消息: ${e.message}');
        print('錯誤詳情: ${e.toString()}');
        print('錯誤堆棧: ${e.stackTrace}');

        // 特別處理權限錯誤
        if (e.code == 'unauthorized' || e.code == 'permission-denied') {
          print('權限被拒絕。請確認：');
          print('1. 用戶是否已登錄');
          print('2. Firebase Storage規則是否正確配置');
          print('3. 用戶是否具有正確的權限');
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
