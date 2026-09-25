import 'package:flutter/material.dart';
import '../../../design_system/presentation/components/system_pill_segment.dart';
import '../../../design_system/presentation/system_theme.dart';
import '../../../domain/enum/attendance_status.dart';
import '../../../domain/model/daily_attendance/student_daily_attendance_info.dart';

/// 單一學生的每日點名卡。
///
/// 狀態以膠囊分段一次呈現全部選項，老師一次點擊即可改變；請假時才展開原因欄。
/// 高度依內容增長（放大文字、請假原因），不設固定高度。
class AttendanceRecordCard extends StatelessWidget {
  final StudentDailyAttendanceRecord student;
  final ValueNotifier<AttendanceStatus> attendStatusNotifier;
  const AttendanceRecordCard(this.student,
      {super.key, required this.attendStatusNotifier});

  static List<SystemPillOption<AttendanceStatus>> get statusOptions => [
        for (final status in AttendanceStatus.values)
          SystemPillOption(
              value: status, label: status.label, toneKey: status.toneKey),
      ];

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<AttendanceStatus>(
        valueListenable: attendStatusNotifier,
        builder: (context, status, _) {
          final ds = SystemTheme.of(context);
          final gap = ds.metric('spaceMedium');
          final tone = ds.color(status.toneKey);
          final name = student.name.trim();
          return Material(
            color: ds.color('secondaryBackground'),
            shape: RoundedRectangleBorder(
                borderRadius: ds.cardRadius,
                side: BorderSide(color: tone.withOpacity(.45), width: 1.5)),
            child: Padding(
              padding: EdgeInsets.all(gap),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      _Initial(name.isEmpty ? '?' : name.characters.first),
                      SizedBox(width: gap * .75),
                      Expanded(
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: ds.metric('bodySize') + 2,
                                  fontWeight: FontWeight.w700,
                                  color: ds.color('primaryText')))),
                      SizedBox(width: gap / 2),
                      AttendanceStatusChip(status),
                    ]),
                    SizedBox(height: gap),
                    SystemPillSegment<AttendanceStatus>(
                      dense: true,
                      options: statusOptions,
                      selected: status,
                      onChanged: (value) => attendStatusNotifier.value = value,
                    ),
                    if (status == AttendanceStatus.leave) ...[
                      SizedBox(height: gap),
                      TextFormField(
                        initialValue: student.leaveReasonNotifier.value,
                        decoration: const InputDecoration(labelText: '請假原因'),
                        style: TextStyle(
                            fontSize: ds.metric('bodySize'),
                            color: ds.color('primaryText')),
                        onChanged: (value) =>
                            student.leaveReasonNotifier.value = value,
                      ),
                    ],
                  ]),
            ),
          );
        },
      );
}

/// 目前狀態的唯讀標籤；文字與顏色同時表達狀態，不只靠顏色。
class AttendanceStatusChip extends StatelessWidget {
  const AttendanceStatusChip(this.status, {super.key});
  final AttendanceStatus status;

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    final tone = ds.color(status.toneKey);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: ds.metric('spaceSmall') * 1.25,
          vertical: ds.metric('spaceSmall') * .5),
      decoration: ShapeDecoration(
          color: ds.statusSurface(status.toneKey),
          shape: const StadiumBorder()),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(status.isAttend ? Icons.check_circle_rounded : Icons.remove_circle,
            size: ds.metric('labelSize') + 2, color: tone),
        SizedBox(width: ds.metric('spaceSmall') * .5),
        Text(status.label,
            style: TextStyle(
                fontSize: ds.metric('labelSize'),
                fontWeight: FontWeight.w700,
                // 淺色底上略壓暗語意色，小字維持 4.5:1。
                color: ds.dark ? tone : Color.lerp(tone, Colors.black, .2)!)),
      ]),
    );
  }
}

class _Initial extends StatelessWidget {
  const _Initial(this.letter);
  final String letter;

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration:
          BoxDecoration(color: ds.brandTone(100), shape: BoxShape.circle),
      child: Text(letter,
          style: TextStyle(
              fontSize: ds.metric('bodySize'),
              fontWeight: FontWeight.w700,
              color: ds.brandTone(700))),
    );
  }
}
