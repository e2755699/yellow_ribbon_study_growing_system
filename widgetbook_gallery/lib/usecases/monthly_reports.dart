import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:yellow_ribbon_study_growing_system/admin/monthly_report_demo.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/components/system_page.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/monthly_attendance_cubit/monthly_attendance_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/roster/monthly_attendance_report.dart';
import 'package:yellow_ribbon_study_growing_system/domain/service/monthly_attendance_service.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/reports/monthly_attendance_view.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/reports/monthly_attendance_table.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/reports/admin_login_view.dart';
import '../gallery_environment.dart';

MonthlyAttendanceReport sampleMonthlyReport(
    {bool long = false, bool cached = false}) {
  final repo = monthlyReportDemoRepository();
  final report = MonthlyAttendanceService.build(
      month: DateTime(2026, 10),
      site: repo.sites.first,
      students: repo.students,
      enrollments: repo.enrollments,
      records: repo.records,
      sessions: repo.sessions,
      fromCache: cached);
  repo.events.close();
  if (!long) return report;
  return MonthlyAttendanceReport(
      month: report.month,
      site: report.site,
      recordCount: report.recordCount,
      sessionCount: report.sessionCount,
      rows: [
        MonthlyAttendanceRow(
            studentId: 'long',
            name: '這是一位用來確認長姓名顯示的合成學生同學',
            days: report.rows.first.days)
      ]);
}

Widget _report(String variant) => ProductPreview(builder: (context) {
      final report = sampleMonthlyReport(cached: variant == 'cached');
      return Padding(
          padding: const EdgeInsets.all(16),
          child: MonthlyAttendanceView(
              state: MonthlyAttendanceState(
                  month: report.month,
                  sites: [report.site],
                  siteId: report.site.id,
                  report: variant == 'empty'
                      ? MonthlyAttendanceReport(
                          month: report.month,
                          site: report.site,
                          rows: const [],
                          recordCount: 0,
                          sessionCount: 0)
                      : report,
                  loading: variant == 'loading',
                  error: variant == 'error' ? '合成網路錯誤，請重新載入。' : null,
                  exporting: variant == 'exporting'),
              demo: true,
              onMonth: (_) {},
              onSite: (_) {},
              onDownload: () {},
              onRetry: () {}));
    });
@widgetbook.UseCase(name: 'Monthly report ready', type: MonthlyAttendanceView)
Widget monthlyReady(BuildContext context) => _report('ready');
@widgetbook.UseCase(name: 'Monthly report loading', type: MonthlyAttendanceView)
Widget monthlyLoading(BuildContext context) => _report('loading');
@widgetbook.UseCase(name: 'Monthly report empty', type: MonthlyAttendanceView)
Widget monthlyEmpty(BuildContext context) => _report('empty');
@widgetbook.UseCase(name: 'Monthly report error', type: MonthlyAttendanceView)
Widget monthlyError(BuildContext context) => _report('error');
@widgetbook.UseCase(
    name: 'Monthly report offline disabled', type: MonthlyAttendanceView)
Widget monthlyOffline(BuildContext context) => _report('cached');
@widgetbook.UseCase(
    name: 'Monthly report exporting disabled', type: MonthlyAttendanceView)
Widget monthlyExporting(BuildContext context) => _report('exporting');
@widgetbook.UseCase(
    name: 'Monthly table with review markers', type: MonthlyAttendanceTable)
Widget monthlyTable(BuildContext context) => ProductPreview(
    builder: (_) => SingleChildScrollView(
        child: MonthlyAttendanceTable(report: sampleMonthlyReport())));
@widgetbook.UseCase(
    name: 'Monthly table long name', type: MonthlyAttendanceTable)
Widget monthlyLong(BuildContext context) => ProductPreview(
    builder: (_) => SingleChildScrollView(
        child:
            MonthlyAttendanceTable(report: sampleMonthlyReport(long: true))));
@widgetbook.UseCase(name: 'Admin sign in', type: AdminLoginView)
Widget adminSignIn(BuildContext context) => ProductPreview(
    builder: (_) => AdminLoginView(
        onDemo: () {}, onLogin: (_, __) async => '合成登入失敗；沒有存取正式後端。'));
@widgetbook.UseCase(name: 'Standalone admin chrome', type: SystemPage)
Widget adminChrome(BuildContext context) => ProductPreview(
    builder: (_) => SystemPage(
        title: '黃絲帶管理後台',
        scaffoldKey: GlobalKey<ScaffoldState>(),
        showBackButton: false,
        child: const Center(child: Text('獨立網站頁面，不顯示返回按鈕'))));
