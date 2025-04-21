import 'package:cloud_firestore/cloud_firestore.dart';

class YellowRibbonCount {
  final String studentId;
  final int totalCount; // 总数
  final int usedCount; // 已使用数量
  final DateTime lastUpdated;

  YellowRibbonCount({
    required this.studentId,
    required this.totalCount,
    required this.usedCount,
    required this.lastUpdated,
  });

  // 获取未使用的数量
  int get unusedCount => totalCount - usedCount;

  // 从 Firestore 数据转换
  factory YellowRibbonCount.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return YellowRibbonCount(
      studentId: doc.id,
      totalCount: data['totalCount'] as int? ?? 0,
      usedCount: data['usedCount'] as int? ?? 0,
      lastUpdated: (data['lastUpdated'] as Timestamp).toDate(),
    );
  }

  // 转换为 Firestore 数据
  Map<String, dynamic> toFirestore() {
    return {
      'totalCount': totalCount,
      'usedCount': usedCount,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }

  // 创建新的记录
  factory YellowRibbonCount.create(String studentId) {
    return YellowRibbonCount(
      studentId: studentId,
      totalCount: 0,
      usedCount: 0,
      lastUpdated: DateTime.now(),
    );
  }

  // 创建更新后的记录
  YellowRibbonCount copyWith({
    int? totalCount,
    int? usedCount,
    DateTime? lastUpdated,
  }) {
    return YellowRibbonCount(
      studentId: studentId,
      totalCount: totalCount ?? this.totalCount,
      usedCount: usedCount ?? this.usedCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}
