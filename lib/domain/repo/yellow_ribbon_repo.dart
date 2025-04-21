import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/yellow_ribbon/yellow_ribbon_count.dart';

class YellowRibbonRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'yellow_ribbon_counts';

  // 获取学生的黄丝带数量
  Future<YellowRibbonCount> getStudentRibbonCount(String studentId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(studentId).get();

      if (doc.exists) {
        return YellowRibbonCount.fromFirestore(doc);
      } else {
        // 如果不存在，创建新记录
        final newCount = YellowRibbonCount.create(studentId);
        await _firestore
            .collection(_collection)
            .doc(studentId)
            .set(newCount.toFirestore());
        return newCount;
      }
    } catch (e) {
      print('Error getting student ribbon count: $e');
      return YellowRibbonCount.create(studentId);
    }
  }

  // 增加黄丝带数量
  Future<bool> incrementRibbonCount(String studentId) async {
    try {
      final currentCount = await getStudentRibbonCount(studentId);

      final updatedCount = currentCount.copyWith(
        totalCount: currentCount.totalCount + 1,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(studentId)
          .set(updatedCount.toFirestore());

      return true;
    } catch (e) {
      print('Error incrementing ribbon count: $e');
      return false;
    }
  }

  // 减少黄丝带数量（用于评级修正）
  Future<bool> decrementUnusedRibbonCount(String studentId) async {
    try {
      final currentCount = await getStudentRibbonCount(studentId);

      // 检查是否有未使用的黄丝带可以减少
      if (currentCount.unusedCount <= 0) {
        return false;
      }

      final updatedCount = currentCount.copyWith(
        usedCount: currentCount.usedCount + 1,
        lastUpdated: DateTime.now(),
      );

      await _firestore
          .collection(_collection)
          .doc(studentId)
          .set(updatedCount.toFirestore());

      return true;
    } catch (e) {
      print('Error decrementing ribbon count: $e');
      return false;
    }
  }

  // 使用黄丝带（用于兑换奖励）
  Future<bool> useRibbon(String studentId) async {
    return decrementUnusedRibbonCount(studentId);
  }
}
