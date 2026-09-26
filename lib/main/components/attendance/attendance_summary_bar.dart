import 'package:flutter/material.dart';
import '../../../design_system/presentation/components/system_page_header.dart';
import '../../../design_system/presentation/system_theme.dart';
import '../../../domain/enum/attendance_status.dart';
import '../../../domain/model/daily_attendance/student_daily_attendance_info.dart';

/// 點名資訊列（位於共用頁首下方）：日期、據點、人數與各狀態統計，隨卡片即時更新。
class AttendanceSummaryBar extends StatelessWidget {
  const AttendanceSummaryBar(
      {super.key,
      required this.records,
      required this.dateLabel,
      required this.locationLabel});
  final List<StudentDailyAttendanceRecord> records;
  final String dateLabel;
  final String locationLabel;

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    final gap = ds.metric('spaceMedium');
    return AnimatedBuilder(
      animation: Listenable.merge(
          [for (final r in records) r.attendanceStatusNotifier]),
      builder: (context, _) {
        final counts = <String, int>{};
        for (final r in records) {
          final group = _group(r.attendanceStatusNotifier.value);
          counts[group] = (counts[group] ?? 0) + 1;
        }
        return SystemPageInfoBar(
          label: '$dateLabel · $locationLabel · 共 ${records.length} 位',
          trailing: Wrap(spacing: gap / 2, runSpacing: gap / 2, children: [
            for (final (label, tone) in _groups)
              _Count(label: label, toneKey: tone, count: counts[label] ?? 0),
          ]),
        );
      },
    );
  }

  static const _groups = [
    ('出席', 'success'),
    ('遲到早退', 'warning'),
    ('請假', 'info'),
    ('缺席', 'error'),
  ];

  static String _group(AttendanceStatus status) => switch (status) {
        AttendanceStatus.attend => '出席',
        AttendanceStatus.late || AttendanceStatus.earlyLeave => '遲到早退',
        AttendanceStatus.leave => '請假',
        AttendanceStatus.absent || AttendanceStatus.busAbsent => '缺席',
      };
}

class _Count extends StatelessWidget {
  const _Count(
      {required this.label, required this.toneKey, required this.count});
  final String label;
  final String toneKey;
  final int count;

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    final tone = ds.color(toneKey);
    return Semantics(
      label: '$label $count 位',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: ds.metric('spaceSmall') * 1.5,
            vertical: ds.metric('spaceSmall') * .75),
        decoration: ShapeDecoration(
            color: ds.color('secondaryBackground'),
            shape:
                StadiumBorder(side: BorderSide(color: tone.withOpacity(.4)))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: tone, shape: BoxShape.circle)),
          SizedBox(width: ds.metric('spaceSmall') * .75),
          Text(label,
              style: TextStyle(
                  fontSize: ds.metric('labelSize'),
                  color: ds.color('secondaryText'))),
          SizedBox(width: ds.metric('spaceSmall') * .75),
          Text('$count',
              style: TextStyle(
                  fontSize: ds.metric('bodySize'),
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: ds.color('primaryText'))),
        ]),
      ),
    );
  }
}
