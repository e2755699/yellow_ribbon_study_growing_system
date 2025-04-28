enum UserRole {
  owner('Owner', 3),
  director('Director', 2),
  teacher('Teacher', 1),
  student('Student', 0);

  final String label;
  final int level; // 權限等級，用於決定用戶可以執行的操作

  const UserRole(this.label, this.level);

  factory UserRole.fromString(String roleStr) {
    return UserRole.values
        .where((role) => role.name == roleStr)
        .first;
  }

  /// 檢查該角色是否具有權限操作一定權限等級的功能
  bool hasPermission(int requiredLevel) {
    return level >= requiredLevel;
  }

  /// 檢查是否可以訪問設置頁面（teacher及以上權限）
  bool get canAccessSettings => level >= UserRole.teacher.level;
} 