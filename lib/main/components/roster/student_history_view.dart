import 'package:flutter/material.dart';
import '../../../design_system/presentation/components/system_page_header.dart';
import '../../../design_system/presentation/components/system_section_card.dart';
import '../../../design_system/presentation/system_theme.dart';
import '../../../domain/enum/attendance_status.dart';
import '../../../domain/roster/student_history_service.dart';
import '../../../domain/roster/roster_models.dart';
import '../attendance/attendance_record_card.dart';
import 'attendance_statistics_card.dart';
import 'performance_record_card.dart';

class StudentHistoryView extends StatelessWidget {
  final String monthLabel;
  final StudentHistory? history;
  final bool loading;
  final String? error;
  final VoidCallback? onPrevious, onNext, onPickMonth, onRetry;
  final ValueChanged<DailyRecord>? onOpenDay;
  const StudentHistoryView(
      {super.key,
      required this.monthLabel,
      this.history,
      this.loading = false,
      this.error,
      this.onPrevious,
      this.onNext,
      this.onPickMonth,
      this.onRetry,
      this.onOpenDay});
  @override
  Widget build(BuildContext context) {
    final gap = SystemTheme.of(context).metric('spaceMedium'), data = history;
    return ListView(children: [
      SystemPageHeader(
          title: data?.name ?? '學生歷史',
          subtitle: '按月份查閱出席、表現與統計。',
          filters: [
            Wrap(
                spacing: gap,
                runSpacing: gap / 2,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  IconButton(
                      onPressed: onPrevious,
                      tooltip: '上一月',
                      icon: const Icon(Icons.chevron_left)),
                  OutlinedButton(
                      onPressed: onPickMonth, child: Text(monthLabel)),
                  IconButton(
                      onPressed: onNext,
                      tooltip: '下一月',
                      icon: const Icon(Icons.chevron_right)),
                ]),
          ]),
      SystemPageInfoBar(
          label:
              '$monthLabel · ${data?.fromCache == true ? '離線資料，待同步' : '每月統計'}'),
      SizedBox(height: gap),
      if (loading)
        const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator())),
      if (error != null)
        Column(children: [
          Text(error!),
          TextButton(onPressed: onRetry, child: const Text('重試'))
        ]),
      if (data != null) ...[
        AttendanceStatisticsCard(
            statistics: data.statistics,
            unknownEnrollmentCoverage: data.unknownEnrollmentCoverage,
            fromCache: data.fromCache),
        SizedBox(height: gap),
        SystemSectionCard(
            title: '本月評量',
            icon: Icons.insights_outlined,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                      '已確認整體表現 ${data.confirmedRatings} 筆 · 記錄 ${data.performance.length} 筆'),
                  const Text('未評分與尚未核對的舊值不列入平均。'),
                  SizedBox(height: gap / 2),
                  Wrap(spacing: gap, runSpacing: gap / 2, children: [
                    for (final metric in PerformanceRecordCard.metrics.entries)
                      Text(
                          '${metric.value}：${data.average(metric.key)?.toStringAsFixed(1) ?? '尚無評量'}'),
                  ]),
                ])),
        SizedBox(height: gap),
        if (data.attendance.isEmpty && data.performance.isEmpty)
          const Text('這個月份尚無每日紀錄'),
        for (final record in [
          ...data.attendance,
          ...data.performance
        ]..sort((a, b) => b.id.compareTo(a.id)))
          Padding(
              key: ValueKey('${record.kind}:${record.id}'),
              padding: EdgeInsets.only(bottom: gap),
              child: SystemSectionCard(
                  title:
                      '${record.date} · ${data.sites.firstWhere((s) => s.id == record.locationId).name} · ${record.kind == 'attendance' ? '出席' : '表現'}',
                  icon: record.kind == 'attendance'
                      ? Icons.fact_check_outlined
                      : Icons.school_outlined,
                  action: TextButton(
                      onPressed:
                          onOpenDay == null ? null : () => onOpenDay!(record),
                      child: const Text('開啟當日紀錄')),
                  child: record.kind == 'attendance'
                      ? AttendanceRecordCard.data(
                          studentName: data.name,
                          status: AttendanceStatus.values
                              .where((s) => s.name == record.values['status'])
                              .firstOrNull,
                          leaveReason:
                              record.values['leaveReason'] as String? ?? '',
                          notice: record.fieldConfirmed('status')
                              ? null
                              : '歷史出席待確認')
                      : PerformanceRecordCard(
                          studentName: data.name,
                          values: record.values,
                          notice: record.provenance == 'confirmed'
                              ? null
                              : '部分歷史評量待確認'))),
      ],
      SizedBox(height: gap * 2),
    ]);
  }
}
