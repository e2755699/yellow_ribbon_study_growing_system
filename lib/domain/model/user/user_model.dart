import 'package:yellow_ribbon_study_growing_system/domain/enum/user_role.dart';

class YbUser {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  YbUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.createdAt,
    this.lastLoginAt,
  });

  /// 從Firebase數據創建一個User對象
  static YbUser fromFirebase(Map<String, dynamic> data, String uid) {
    return YbUser(
      uid: uid,
      email: data['email'] as String,
      displayName: data['displayName'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String? ?? 'student'),
      createdAt: (data['createdAt'] == null)
          ? DateTime.now()
          : DateTime.fromMillisecondsSinceEpoch(
              data['createdAt'].millisecondsSinceEpoch),
      lastLoginAt: (data['lastLoginAt'] == null)
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              data['lastLoginAt'].millisecondsSinceEpoch),
    );
  }

  /// 將User對象轉換為Firebase數據
  Map<String, dynamic> toFirebase() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.name,
      'createdAt': createdAt,
      'lastLoginAt': lastLoginAt,
    };
  }

  /// 檢查是否可以訪問設置頁面
  bool get canAccessSettings => role.canAccessSettings;

  /// 創建一個新的User對象，帶有更新的屬性
  YbUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return YbUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
} 