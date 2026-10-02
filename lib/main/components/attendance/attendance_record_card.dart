import 'package:flutter/material.dart';
import '../../../design_system/presentation/components/system_pill_segment.dart';
import '../../../design_system/presentation/system_theme.dart';
import '../../../domain/enum/attendance_status.dart';
import '../../../domain/model/daily_attendance/student_daily_attendance_info.dart';
import '../roster/record_text_field.dart';

/// Production card. The legacy constructor only adapts its old notifier model;
/// all rendering and new production callers use the immutable data constructor.
class AttendanceRecordCard extends StatelessWidget {
  final StudentDailyAttendanceRecord? student;
  final ValueNotifier<AttendanceStatus>? attendStatusNotifier;
  final String? studentName;
  final AttendanceStatus? status;
  final String leaveReason;
  final ValueChanged<AttendanceStatus?>? onStatusChanged;
  final ValueChanged<String>? onReasonChanged;
  final String? notice;
  const AttendanceRecordCard(this.student,
      {super.key, required this.attendStatusNotifier})
      : studentName = null,
        status = null,
        leaveReason = '',
        onStatusChanged = null,
        onReasonChanged = null,
        notice = null;
  const AttendanceRecordCard.data(
      {super.key,
      required this.studentName,
      this.status,
      this.leaveReason = '',
      this.onStatusChanged,
      this.onReasonChanged,
      this.notice})
      : student = null,
        attendStatusNotifier = null;
  static List<SystemPillOption<AttendanceStatus?>> get statusOptions => [
        const SystemPillOption(value: null, label: '未點名', toneKey: 'info'),
        for (final status in AttendanceStatus.values)
          SystemPillOption(
              value: status, label: status.label, toneKey: status.toneKey),
      ];
  @override
  Widget build(BuildContext context) {
    if (student != null)
      return ValueListenableBuilder<AttendanceStatus>(
          valueListenable: attendStatusNotifier!,
          builder: (context, value, _) => AttendanceRecordCard.data(
              studentName: student!.name,
              status: value,
              leaveReason: student!.leaveReasonNotifier.value,
              onStatusChanged: (next) {
                if (next != null) attendStatusNotifier!.value = next;
              },
              onReasonChanged: (value) =>
                  student!.leaveReasonNotifier.value = value));
    final ds = SystemTheme.of(context),
        gap = SystemTheme.of(context).metric('spaceMedium');
    return Container(
        decoration: ds.cardDecoration,
        padding: EdgeInsets.all(gap),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: gap,
              runSpacing: gap / 2,
              children: [
                Text(studentName ?? '',
                    style: TextStyle(
                        fontSize: ds.metric('titleSize'),
                        fontWeight: FontWeight.w700,
                        color: ds.color('primaryText'))),
                AttendanceStatusChip(status),
              ]),
          SizedBox(height: gap),
          SystemPillSegment<AttendanceStatus?>(
              options: statusOptions,
              selected: status,
              onChanged: onStatusChanged,
              dense: true),
          if (status == AttendanceStatus.leave) ...[
            SizedBox(height: gap),
            RecordTextField(
                value: leaveReason, label: '請假原因', onChanged: onReasonChanged),
          ],
          if (notice != null) ...[
            SizedBox(height: gap / 2),
            Text(notice!,
                style: TextStyle(
                    fontSize: ds.metric('labelSize'),
                    color: ds.color('secondaryText'))),
          ],
        ]));
  }
}

class AttendanceStatusChip extends StatelessWidget {
  const AttendanceStatusChip(this.status, {super.key});
  final AttendanceStatus? status;
  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context), key = status?.toneKey ?? 'info';
    return Container(
        padding: EdgeInsets.symmetric(
            horizontal: ds.metric('spaceSmall') * 1.25,
            vertical: ds.metric('spaceSmall') * .75),
        decoration: ShapeDecoration(
            color: ds.statusSurface(key), shape: const StadiumBorder()),
        child: Text(status?.label ?? '未點名',
            style: TextStyle(
                fontSize: ds.metric('labelSize'),
                fontWeight: FontWeight.w700,
                color: ds.color('primaryText'))));
  }
}
