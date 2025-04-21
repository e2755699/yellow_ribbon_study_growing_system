import 'package:cloud_firestore/cloud_firestore.dart';

enum YellowRibbonType {
  excellentPerformance, // 优秀表现
  homeworkCompletion, // 作业完成
  helpingOthers, // 助人为乐
  specialAchievement, // 特殊成就
  // ... 未来可以继续添加其他获得黄丝带的类型
}

class YellowRibbonRecord {
  final String id;
  final String studentId;
  final YellowRibbonType type;
  final DateTime awardDate;
  final String reason; // 获得黄丝带的具体原因
  final String awardedBy; // 颁发老师的ID
  final bool isUsed; // 是否已经使用/兑换
  final String? usedFor; // 使用/兑换的项目
  final DateTime? usedDate; // 使用/兑换的日期

  YellowRibbonRecord({
    required this.id,
    required this.studentId,
    required this.type,
    required this.awardDate,
    required this.reason,
    required this.awardedBy,
    this.isUsed = false,
    this.usedFor,
    this.usedDate,
  });

  // 从 Firestore 数据转换为 YellowRibbonRecord
  factory YellowRibbonRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return YellowRibbonRecord(
      id: doc.id,
      studentId: data['studentId'] as String,
      type: YellowRibbonType.values.firstWhere(
        (e) => e.toString() == 'YellowRibbonType.${data['type']}',
      ),
      awardDate: (data['awardDate'] as Timestamp).toDate(),
      reason: data['reason'] as String,
      awardedBy: data['awardedBy'] as String,
      isUsed: data['isUsed'] as bool? ?? false,
      usedFor: data['usedFor'] as String?,
      usedDate: data['usedDate'] != null
          ? (data['usedDate'] as Timestamp).toDate()
          : null,
    );
  }

  // 转换为 Firestore 数据
  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'type': type.toString().split('.').last,
      'awardDate': Timestamp.fromDate(awardDate),
      'reason': reason,
      'awardedBy': awardedBy,
      'isUsed': isUsed,
      'usedFor': usedFor,
      'usedDate': usedDate != null ? Timestamp.fromDate(usedDate!) : null,
    };
  }

  // 创建一个新的黄丝带记录
  static YellowRibbonRecord create({
    required String studentId,
    required YellowRibbonType type,
    required String reason,
    required String awardedBy,
  }) {
    return YellowRibbonRecord(
      id: '', // Firestore 会自动生成 ID
      studentId: studentId,
      type: type,
      awardDate: DateTime.now(),
      reason: reason,
      awardedBy: awardedBy,
    );
  }
}
