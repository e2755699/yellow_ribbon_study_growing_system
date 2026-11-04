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
  String get rateLabel =>
      rate == null ? '待確認' : '${(rate! * 100).round()}%${isFinal ? '' : '*'}';
  List<String> get statistics => [
        '$expected',
        '$present',
        '$sick',
        '$personal',
        '$otherLeave',
        '$absent',
        '$busAbsent',
        '$missing',
        '$pending',
        rateLabel
      ];
}

const monthlyAttendanceStatistics = [
  '應出席',
  '實到',
  '病假',
  '事假',
  '假未分類',
  '無故缺席',
  '校車缺席',
  '未點名',
  '待核對',
  '出席率'
];
const monthlyAttendanceLegend = '出席 ○　病假 ＋　事假 △　缺席 ×　遲到 遲　早退 早　請假未分類 請　校車缺席 車';
const monthlyAttendanceNotes = [
  '灰底僅標示週末，不代表放假。空白表示沒有既存紀錄或不在有效就讀期間；? 表示已確認課次但未點名。',
  '符號後 ? 表示出席狀態未確認；＊表示課次或就讀期間待核對。待核對資料不納入已確認出缺席。',
  '應出席依已確認有上課的課次與有效就讀期間計算。未建立課次的日期不推定為放假。',
  '出席率＝實到（含遲到、早退）÷已確認有效點名數；* 表示暫計，不能當作完整的正式月出席率。',
  '病假、事假僅依明確填寫的原因分類，其餘保留未分類。系統沒有年級欄位，因此留白。',
];
