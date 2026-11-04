import 'roster_models.dart';

/// One immutable report snapshot shared by the screen and PDF export.
class MonthlyAttendanceReport {
  const MonthlyAttendanceReport(
      {required this.month,
      required this.site,
      required this.rows,
      required this.recordCount,
      required this.sessionCount,
      this.fromCache = false});
  final DateTime month;
  final ClassSite site;
  final List<MonthlyAttendanceRow> rows;
  final int recordCount, sessionCount;
  final bool fromCache;
  int get days => DateTime(month.year, month.month + 1, 0).day;
  String get monthKey =>
      '${month.year}-${month.month.toString().padLeft(2, '0')}';
  String get label => '${month.year} 年 ${month.month} 月';
  int get pending => rows.fold(0, (sum, row) => sum + row.pending);
  int get missing => rows.fold(0, (sum, row) => sum + row.missing);
  int get present => rows.fold(0, (sum, row) => sum + row.present);
  int get confirmed => rows.fold(0, (sum, row) => sum + row.confirmed);
}

class MonthlyAttendanceDay {
  const MonthlyAttendanceDay(this.symbol, this.description,
      {this.needsReview = false, this.expected = false});
  final String symbol, description;
  final bool needsReview, expected;
}

class MonthlyAttendanceRow {
  const MonthlyAttendanceRow(
      {required this.studentId,
      required this.name,
      required this.days,
      this.expected = 0,
      this.present = 0,
      this.sick = 0,
      this.personal = 0,
      this.otherLeave = 0,
      this.absent = 0,
      this.busAbsent = 0,
      this.missing = 0,
      this.pending = 0,
      this.uncertainSessions = 0});
  final String studentId, name;
  final List<MonthlyAttendanceDay> days;
  final int expected,
      present,
      sick,
      personal,
      otherLeave,
      absent,
      busAbsent,
      missing,
      pending,
      uncertainSessions;
  int get confirmed =>
      present + sick + personal + otherLeave + absent + busAbsent;
  bool get isFinal =>
      expected > 0 &&
      confirmed == expected &&
      pending == 0 &&
      uncertainSessions == 0;
  double? get rate => confirmed == 0 ? null : present / confirmed;
  String get rateLabel => rate == null ? '' : '${(rate! * 100).round()}%';
  List<String> get statistics =>
      ['$expected', '$present', '$sick', '$personal', '$absent', rateLabel];
}

const monthlyAttendanceStatistics = [
  '應出席天數',
  '實際出席天數',
  '病假',
  '事假',
  '無故',
  '出席率'
];
const monthlyAttendanceLegend = '出席 ○　病假 ＋　事假 △　缺席 ×　遲到 遲　早退 早　請假未分類 請　校車缺席 車';
const monthlyAttendanceNotes = [
  '點名依原始紀錄呈現；空白表示沒有紀錄，灰底標示週末。',
  '出席率＝實到（含遲到、早退）÷已有出缺席紀錄數；沒有紀錄的日期不補成缺席。',
  '病假、事假依原填原因分類；其他請假保留「請」，指向格子可查看原始原因。年級沒有資料時留白。',
];
