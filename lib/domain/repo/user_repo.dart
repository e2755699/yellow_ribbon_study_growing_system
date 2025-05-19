import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/user_role.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/user/user_model.dart';

class UserRepo {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'users';

  /// 獲取當前用戶的角色
  Future<UserRole> getCurrentUserRole() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return UserRole.student; // 默認為學生角色
    }

    try {
      final userDoc = await _firestore
          .collection(_collectionName)
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        final userData = userDoc.data()!;
        return UserRole.fromString(userData['role'] as String? ?? 'student');
      } else {
        // 如果用戶文檔不存在，創建默認用戶文檔
        final defaultUser = YbUser(
          uid: currentUser.uid,
          email: currentUser.email ?? '',
          displayName: currentUser.displayName ?? '',
          role: UserRole.student,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(_collectionName)
            .doc(currentUser.uid)
            .set(defaultUser.toFirebase());

        return UserRole.student;
      }
    } catch (e) {
      print('Error getting user role: $e');
      return UserRole.student;
    }
  }

  /// 獲取當前用戶信息
  Future<YbUser?> getCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return null;
    }

    try {
      final userDoc = await _firestore
          .collection(_collectionName)
          .doc(currentUser.uid)
          .get();

      if (userDoc.exists) {
        return YbUser.fromFirebase(userDoc.data()!, currentUser.uid);
      } else {
        // 如果用戶文檔不存在，創建默認用戶文檔
        final defaultUser = YbUser(
          uid: currentUser.uid,
          email: currentUser.email ?? '',
          displayName: currentUser.displayName ?? '',
          role: UserRole.student,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(_collectionName)
            .doc(currentUser.uid)
            .set(defaultUser.toFirebase());

        return defaultUser;
      }
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// 更新用戶角色
  Future<void> updateUserRole(String uid, UserRole role) async {
    try {
      await _firestore.collection(_collectionName).doc(uid).update({
        'role': role.name,
      });
    } catch (e) {
      print('Error updating user role: $e');
      throw Exception('更新用戶角色失敗，請重試');
    }
  }

  /// 檢查當前用戶是否可以訪問設置頁面
  Future<bool> canAccessSettings() async {
    final userRole = await getCurrentUserRole();
    return userRole.canAccessSettings;
  }
} 