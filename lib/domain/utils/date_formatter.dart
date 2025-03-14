/// 日期格式化工具类
class DateFormatter {
  /// 将日期格式化为 yyyy-MM-dd 格式
  static String formatToYYYYMMDD(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  /// 将日期格式化为文档ID格式（yyyy-MM-dd_classLocation）
  static String formatToDocId(DateTime date, String classLocation) {
    return "${formatToYYYYMMDD(date)}_$classLocation";
  }

  /// 从文档ID中提取日期（假设文档ID格式为 yyyy-MM-dd_classLocation）
  static DateTime? extractDateFromDocId(String docId) {
    try {
      final parts = docId.split('_');
      if (parts.isNotEmpty) {
        return DateTime.parse(parts[0]);
      }
    } catch (e) {
      print('Error extracting date from docId: $e');
    }
    return null;
  }
} 