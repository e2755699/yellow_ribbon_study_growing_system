/// 出缺勤狀態。`name` 為 Firestore 儲存值，勿更名。
enum AttendanceStatus {
  attend("出席", 'success'),
  late("遲到", 'warning'),
  earlyLeave("早退", 'warning'),
  leave("請假", 'info'),
  absent("缺席", 'error'),
  busAbsent("校車缺席", 'error');

  final String label;

  /// SystemTheme 語意色 key，由畫面依目前主題與明暗解析成實際顏色。
  final String toneKey;

  const AttendanceStatus(this.label, this.toneKey);

  factory AttendanceStatus.fromString(String statusStr) {
    //todo error handle
    return AttendanceStatus.values
        .where((status) => status.name == statusStr)
        .first;
  }

  bool get isAttend =>
      this == AttendanceStatus.attend ||
      this == AttendanceStatus.late ||
      this == AttendanceStatus.earlyLeave;
}
