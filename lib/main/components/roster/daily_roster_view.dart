import 'package:flutter/material.dart';
import '../../../design_system/presentation/components/system_page_header.dart';
import '../../../design_system/presentation/components/system_section_card.dart';
import '../../../design_system/presentation/system_theme.dart';
import '../../../domain/enum/attendance_status.dart';
import '../../../domain/roster/roster_models.dart';
import '../attendance/attendance_record_card.dart';
import 'performance_record_card.dart';

class RosterRowViewData {
  final String id, name;
  final Map<String, dynamic> values;
  final bool dirty, enabled, orphan, needsConfirmation;
  final bool canResolveConflict, canDiscard;
  final String? notice, error;
  const RosterRowViewData(
      {required this.id,
      required this.name,
      required this.values,
      this.dirty = false,
      this.enabled = true,
      this.orphan = false,
      this.needsConfirmation = false,
      this.canResolveConflict = false,
      this.canDiscard = true,
      this.notice,
      this.error});
}

/// Pure production view shared by both routes and offline Widgetbook cases.
class DailyRosterView extends StatelessWidget {
  final String kind, dateLabel, summary;
  final String? locationId, error, notice, saveMessage;
  final List<ClassSite> sites;
  final List<RosterRowViewData> rows;
  final bool loading, saving, canSave;
  final bool saveIncomplete;
  final VoidCallback? onSave,
      onRetry,
      onPickDate,
      onConfirmSession,
      onCancelSession;
  final ValueChanged<String>? onLocationChanged, onSearch, onStatusFilter;
  final void Function(String, String, dynamic)? onEdit;
  final ValueChanged<String>? onDiscard,
      onKeepLocal,
      onExpand,
      onConfirm,
      onReviewEnrollment;
  const DailyRosterView(
      {super.key,
      required this.kind,
      required this.dateLabel,
      required this.summary,
      this.locationId,
      this.error,
      this.notice,
      this.saveMessage,
      this.saveIncomplete = false,
      this.sites = const [],
      this.rows = const [],
      this.loading = false,
      this.saving = false,
      this.canSave = false,
      this.onSave,
      this.onRetry,
      this.onPickDate,
      this.onConfirmSession,
      this.onCancelSession,
      this.onLocationChanged,
      this.onSearch,
      this.onStatusFilter,
      this.onEdit,
      this.onDiscard,
      this.onKeepLocal,
      this.onExpand,
      this.onConfirm,
      this.onReviewEnrollment});

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context),
        gap = SystemTheme.of(context).metric('spaceMedium');
    return LayoutBuilder(builder: (context, constraints) {
      // Structural breakpoint: two usable cards require at least 420px each.
      final columns = constraints.maxWidth >= 900 ? 2 : 1;
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return SingleChildScrollView(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SystemPageHeader(
            title: kind == 'attendance' ? '每日出席' : '每日表現',
            subtitle: '依當日有效名冊顯示，修改完成後請儲存。',
            action: ElevatedButton.icon(
                onPressed: canSave && !saving ? onSave : null,
                icon: const Icon(Icons.save_outlined),
                label: Text(saving
                    ? '儲存中…'
                    : saveIncomplete
                        ? '重試儲存'
                        : '儲存修改')),
            filters: [
              DropdownButtonFormField<String>(
                  key: ValueKey(locationId),
                  initialValue:
                      sites.any((s) => s.id == locationId) ? locationId : null,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: '據點'),
                  items: [
                    for (final site in sites)
                      DropdownMenuItem(value: site.id, child: Text(site.name))
                  ],
                  onChanged: saving
                      ? null
                      : (value) {
                          if (value != null) onLocationChanged?.call(value);
                        }),
              OutlinedButton.icon(
                  onPressed: saving ? null : onPickDate,
                  icon: const Icon(Icons.calendar_month),
                  label: Text(dateLabel)),
              TextField(
                  decoration: const InputDecoration(
                      labelText: '搜尋學生', prefixIcon: Icon(Icons.search)),
                  onChanged: onSearch),
            ]),
        SizedBox(height: gap),
        if (saveMessage != null) ...[
          Semantics(
              liveRegion: true,
              child: SystemSectionCard(
                  title: saveIncomplete ? '儲存尚未完成' : '儲存成功',
                  icon: saveIncomplete
                      ? Icons.error_outline
                      : Icons.check_circle_outline,
                  child: Text(saveMessage!,
                      style: TextStyle(
                          fontSize: ds.metric('bodySize'),
                          color: ds.color('primaryText'))))),
          SizedBox(height: gap),
        ],
        SystemPageInfoBar(
            label: summary,
            trailing: kind == 'attendance'
                ? Wrap(spacing: gap, runSpacing: gap / 2, children: [
                    OutlinedButton(
                        onPressed: onStatusFilter == null
                            ? null
                            : () => onStatusFilter!('unmarked'),
                        child: const Text('只看未點名')),
                    TextButton(
                        onPressed: onStatusFilter == null
                            ? null
                            : () => onStatusFilter!('all'),
                        child: const Text('顯示全部')),
                    if (onConfirmSession != null)
                      TextButton(
                          onPressed: onConfirmSession,
                          child: const Text('確認本日有上課')),
                    if (onCancelSession != null)
                      TextButton(
                          onPressed: onCancelSession,
                          child: const Text('取消本日上課')),
                  ])
                : null),
        if (notice != null)
          Padding(
              padding: EdgeInsets.symmetric(vertical: gap / 2),
              child: Semantics(
                  liveRegion: true,
                  child: Text(notice!,
                      style: TextStyle(color: ds.color('secondaryText'))))),
        if (error != null)
          Padding(
              padding: EdgeInsets.symmetric(vertical: gap / 2),
              child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: gap,
                  children: [
                    Text(error!, style: TextStyle(color: ds.color('error'))),
                    TextButton(onPressed: onRetry, child: const Text('重試')),
                  ])),
        if (loading)
          const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator())),
        if (!loading && rows.isEmpty && error == null)
          Padding(
              padding: EdgeInsets.all(gap * 2),
              child: const Text('此日期沒有符合條件的學生')),
        SizedBox(height: gap),
        Wrap(spacing: gap, runSpacing: gap, children: [
          for (final row in rows)
            SizedBox(
                key: ValueKey(row.id),
                width: width,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (kind == 'attendance')
                        AttendanceRecordCard.data(
                            studentName: row.name,
                            status: AttendanceStatus.values
                                .where((status) =>
                                    status.name == row.values['status'])
                                .firstOrNull,
                            leaveReason:
                                row.values['leaveReason'] as String? ?? '',
                            notice: row.notice,
                            onStatusChanged: row.enabled && onEdit != null
                                ? (status) =>
                                    onEdit!(row.id, 'status', status?.name)
                                : null,
                            onReasonChanged: row.enabled && onEdit != null
                                ? (reason) =>
                                    onEdit!(row.id, 'leaveReason', reason)
                                : null),
                      if (kind == 'performance')
                        PerformanceRecordCard(
                            studentName: row.name,
                            values: row.values,
                            notice: row.notice,
                            onChanged: row.enabled && onEdit != null
                                ? (field, value) =>
                                    onEdit!(row.id, field, value)
                                : null,
                            onExpand: onExpand == null
                                ? null
                                : () => onExpand!(row.id)),
                      if (row.orphan && onReviewEnrollment != null)
                        TextButton(
                            onPressed: saving
                                ? null
                                : () => onReviewEnrollment!(row.id),
                            child: const Text('核對學生就讀期間')),
                      if (row.error != null)
                        Padding(
                            padding: EdgeInsets.all(gap / 2),
                            child: Text(row.error!,
                                style: TextStyle(color: ds.color('error')))),
                      if (row.enabled && row.needsConfirmation)
                        TextButton(
                            onPressed: saving || onConfirm == null
                                ? null
                                : () => onConfirm!(row.id),
                            child: const Text('已核對，確認本筆資料')),
                      if (row.dirty)
                        Wrap(spacing: gap, children: [
                          TextButton(
                              onPressed:
                                  saving || !row.canDiscard || onDiscard == null
                                      ? null
                                      : () => onDiscard!(row.id),
                              child: const Text('捨棄本筆修改')),
                          if (row.canResolveConflict)
                            TextButton(
                                onPressed: saving || onKeepLocal == null
                                    ? null
                                    : () => onKeepLocal?.call(row.id),
                                child: const Text('核對後保留我的修改')),
                        ]),
                    ])),
        ]),
        SizedBox(height: gap * 2),
      ]));
    });
  }
}
