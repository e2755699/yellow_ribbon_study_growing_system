import 'package:flutter/material.dart';
import '../../../design_system/presentation/components/system_page_header.dart';
import '../../../design_system/presentation/components/system_section_card.dart';
import '../../../design_system/presentation/system_theme.dart';
import '../../../domain/bloc/monthly_attendance_cubit/monthly_attendance_cubit.dart';
import '../../../domain/model/roster/monthly_attendance_report.dart';
import 'monthly_attendance_table.dart';

class MonthlyAttendanceView extends StatelessWidget {
  const MonthlyAttendanceView(
      {super.key,
      required this.state,
      required this.onMonth,
      required this.onSite,
      required this.onDownload,
      required this.onRetry,
      this.demo = false,
      this.onExit,
      this.onTheme});
  final MonthlyAttendanceState state;
  final ValueChanged<DateTime> onMonth;
  final ValueChanged<String?> onSite;
  final VoidCallback onDownload, onRetry;
  final VoidCallback? onExit, onTheme;
  final bool demo;
  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context),
        gap = SystemTheme.of(context).metric('spaceMedium');
    final report = state.report;
    Widget notice(String title, String message, IconData icon,
            {bool retry = false, bool busy = false}) =>
        SystemSectionCard(
            title: title,
            icon: icon,
            child: Padding(
                padding: EdgeInsets.symmetric(vertical: gap),
                child: Column(children: [
                  if (busy)
                    const CircularProgressIndicator()
                  else
                    Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                            color: ds.surfaceTone(100), shape: BoxShape.circle),
                        child: Icon(icon, size: 30, color: ds.brandTone(700))),
                  SizedBox(height: gap),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: ds.metric('bodySize'),
                          color: ds.color('primaryText'))),
                  if (retry) ...[
                    SizedBox(height: gap),
                    OutlinedButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh),
                        label: const Text('重新載入'))
                  ],
                ])));
    return SingleChildScrollView(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: gap,
              runSpacing: gap / 2,
              children: [
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.spa_outlined, color: ds.brandTone(700)),
                  SizedBox(width: ds.metric('spaceSmall')),
                  Text('黃絲帶 · 管理後台',
                      style: TextStyle(
                          fontSize: ds.metric('titleSize'),
                          fontWeight: FontWeight.w700,
                          color: ds.color('primaryText')))
                ]),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  if (demo)
                    Padding(
                        padding: EdgeInsets.only(right: gap / 2),
                        child: Text('示範資料',
                            style: TextStyle(
                                color: ds.color('info'),
                                fontSize: ds.metric('labelSize')))),
                  if (onTheme != null)
                    IconButton(
                        tooltip: '切換明暗模式',
                        onPressed: onTheme,
                        icon: const Icon(Icons.brightness_6_outlined)),
                  if (onExit != null)
                    TextButton.icon(
                        onPressed: onExit,
                        icon: Icon(demo ? Icons.login : Icons.logout, size: 18),
                        label: Text(demo ? '登入正式資料' : '登出')),
                ]),
              ])),
      SystemPageHeader(
          title: '月出席報表',
          subtitle: '查看整月點名紀錄，下載橫式出席表。',
          action: ElevatedButton.icon(
              key: const ValueKey('download-monthly-pdf'),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(150, 48),
                  textStyle: TextStyle(
                      fontSize: ds.metric('bodySize'),
                      fontWeight: FontWeight.w700)),
              onPressed: state.canExport ? onDownload : null,
              icon: state.exporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.file_download_outlined),
              label: Text(state.exporting ? '正在產生 PDF' : '下載 PDF')),
          filters: [
            _MonthField(month: state.month, onChanged: onMonth),
            DropdownButtonFormField<String>(
                key: ValueKey('site-${state.siteId}-${state.sites.length}'),
                initialValue: state.sites.any((s) => s.id == state.siteId)
                    ? state.siteId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: '據點',
                    prefixIcon: Icon(Icons.location_on_outlined)),
                items: [
                  for (final site in state.sites)
                    DropdownMenuItem(
                        value: site.id,
                        child: Text(site.name, overflow: TextOverflow.ellipsis))
                ],
                onChanged: state.sites.isEmpty ? null : onSite),
          ]),
      SystemPageInfoBar(
          label:
              '${state.month.year} 年 ${state.month.month} 月${report == null ? '' : ' · ${report.site.name} · ${report.rows.length} 位學生'}',
          trailing: Text(
              state.loading
                  ? '讀取中'
                  : state.error != null
                      ? '尚未完成載入'
                      : report?.fromCache == true
                          ? '離線資料 · 暫不可下載'
                          : demo
                              ? '合成資料 · 可操作下載'
                              : '即時同步',
              style: TextStyle(
                  fontSize: ds.metric('labelSize'),
                  color: ds.color(
                      state.error != null ? 'error' : 'secondaryText')))),
      if (state.loading)
        notice('正在整理報表', '正在讀取名冊、課次與出席紀錄…', Icons.hourglass_empty, busy: true)
      else if (state.error != null)
        notice('報表暫時無法載入', state.error!, Icons.cloud_off_outlined, retry: true)
      else if (report == null || report.rows.isEmpty)
        notice(
            '這個月份還沒有資料', '請切換月份或據點；沒有點名紀錄不會被補成缺席。', Icons.event_note_outlined)
      else ...[
        LayoutBuilder(builder: (context, box) {
          final items = [
            (
              '學生人數',
              '${report.rows.length}',
              '依本月有效期間與既存紀錄',
              Icons.people_outline
            ),
            (
              '有上課課次',
              '${report.sessionCount}',
              '依系統已確認課次',
              Icons.calendar_month_outlined
            ),
            (
              '待處理紀錄',
              '${report.pending + report.missing}',
              '待核對 ${report.pending} · 未點名 ${report.missing}',
              Icons.fact_check_outlined
            )
          ];
          final narrow = box.maxWidth < 680;
          return Wrap(spacing: gap, runSpacing: gap, children: [
            for (final item in items)
              SizedBox(
                  width: narrow ? box.maxWidth : (box.maxWidth - gap * 2) / 3,
                  child: Container(
                      padding: EdgeInsets.all(gap),
                      decoration: ds.cardDecoration,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Icon(item.$4, size: 22, color: ds.brandTone(700)),
                              SizedBox(width: gap / 2),
                              Expanded(
                                  child: Text(item.$1,
                                      style: TextStyle(
                                          fontSize: ds.metric('bodySize'),
                                          color: ds.color('secondaryText'))))
                            ]),
                            SizedBox(height: gap / 2),
                            Text(item.$2,
                                style: TextStyle(
                                    fontSize: ds.metric('headingSize'),
                                    fontWeight: FontWeight.w700,
                                    color: ds.color('primaryText'))),
                            Text(item.$3,
                                style: TextStyle(
                                    fontSize: ds.metric('labelSize'),
                                    color: ds.color('secondaryText'))),
                          ]))),
          ]);
        }),
        SizedBox(height: gap),
        SystemSectionCard(
            title: '${report.label}出席紀錄表',
            icon: Icons.table_chart_outlined,
            action: Padding(
                padding: EdgeInsets.only(left: gap / 2),
                child: Text('A4 橫式 · 自動分頁',
                    style: TextStyle(
                        fontSize: ds.metric('labelSize'),
                        color: ds.color('secondaryText')))),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(report.site.name,
                      style: TextStyle(
                          fontSize: ds.metric('titleSize'),
                          fontWeight: FontWeight.w700,
                          color: ds.color('primaryText'))),
                  SizedBox(height: gap / 2),
                  Text(monthlyAttendanceLegend,
                      style: TextStyle(
                          fontSize: ds.metric('labelSize'),
                          color: ds.color('secondaryText'),
                          height: 1.8)),
                  SizedBox(height: gap),
                  MonthlyAttendanceTable(
                      key: ValueKey('${report.site.id}-${report.monthKey}'),
                      report: report),
                ])),
        SizedBox(height: gap),
        SystemSectionCard(
            title: '統計與符號說明',
            icon: Icons.info_outline,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final note in monthlyAttendanceNotes)
                    Padding(
                        padding: EdgeInsets.only(bottom: gap / 2),
                        child: Text(note,
                            style: TextStyle(
                                fontSize: ds.metric('labelSize'),
                                color: ds.color('secondaryText'),
                                height: 1.6)))
                ])),
      ],
      SizedBox(height: ds.metric('spaceLarge')),
    ]));
  }
}

class _MonthField extends StatelessWidget {
  const _MonthField({required this.month, required this.onChanged});
  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  @override
  Widget build(BuildContext context) => InputDecorator(
      decoration: const InputDecoration(
          labelText: '報表月份',
          contentPadding: EdgeInsets.symmetric(horizontal: 4)),
      child: Row(children: [
        IconButton(
            tooltip: '上一個月',
            onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
            icon: const Icon(Icons.chevron_left)),
        Expanded(
            child: TextButton(
                onPressed: () async {
                  final selected = await showDatePicker(
                      context: context,
                      initialDate: month,
                      firstDate: DateTime(1900),
                      lastDate: DateTime(9998, 12, 31),
                      helpText: '選擇報表月份中的任一天');
                  if (selected != null) {
                    onChanged(DateTime(selected.year, selected.month));
                  }
                },
                child: Text('${month.year} 年 ${month.month} 月'))),
        IconButton(
            tooltip: '下一個月',
            onPressed: () => onChanged(DateTime(month.year, month.month + 1)),
            icon: const Icon(Icons.chevron_right)),
      ]));
}
