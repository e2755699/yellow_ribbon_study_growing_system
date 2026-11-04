import 'package:flutter/material.dart';
import '../../../design_system/presentation/system_theme.dart';
import '../../../domain/model/roster/monthly_attendance_report.dart';

/// The same production report table is used by Admin and Widgetbook.
class MonthlyAttendanceTable extends StatefulWidget {
  const MonthlyAttendanceTable({super.key, required this.report});
  final MonthlyAttendanceReport report;
  @override
  State<MonthlyAttendanceTable> createState() => _MonthlyAttendanceTableState();
}

class _MonthlyAttendanceTableState extends State<MonthlyAttendanceTable> {
  final _horizontal = ScrollController();
  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context), report = widget.report;
    const rowHeight = 44.0, headingHeight = 60.0;
    Widget cell(String value, double width,
        {bool header = false,
        bool weekend = false,
        bool warning = false,
        String? tooltip,
        double? height}) {
      final child = Container(
          width: width,
          height: height ?? (header ? headingHeight : rowHeight),
          alignment: Alignment.center,
          padding:
              EdgeInsets.symmetric(horizontal: ds.metric('spaceSmall') / 2),
          decoration: BoxDecoration(
              color: warning
                  ? ds.statusSurface('warning')
                  : weekend
                      ? ds.color('alternate').withValues(alpha: .4)
                      : header
                          ? ds.surfaceTone(100)
                          : ds.color('secondaryBackground'),
              border: Border(right: ds.cardBorder, bottom: ds.cardBorder)),
          child: Text(value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color:
                      warning ? ds.color('warning') : ds.color('primaryText'),
                  fontSize: ds.metric('labelSize'),
                  fontWeight: header ? FontWeight.w700 : FontWeight.w500)));
      return tooltip == null || tooltip.isEmpty
          ? child
          : Tooltip(message: tooltip, child: child);
    }

    return LayoutBuilder(builder: (context, box) {
      final compact = box.maxWidth < 650;
      final nameWidth = compact ? 112.0 : 160.0;
      final indexWidth = compact ? 36.0 : 44.0;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Row(children: [
              cell('編號', indexWidth, header: true),
              cell('姓名', nameWidth, header: true)
            ]),
            for (var i = 0; i < report.rows.length; i++)
              Row(children: [
                cell('${i + 1}', indexWidth),
                cell(report.rows[i].name, nameWidth,
                    tooltip: report.rows[i].name),
              ]),
          ]),
          Expanded(
              child: Scrollbar(
                  controller: _horizontal,
                  thumbVisibility: true,
                  notificationPredicate: (n) => n.depth == 0,
                  child: SingleChildScrollView(
                      controller: _horizontal,
                      scrollDirection: Axis.horizontal,
                      padding:
                          EdgeInsets.only(bottom: ds.metric('spaceMedium')),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              cell('年級', 48, header: true),
                              for (var d = 1; d <= report.days; d++)
                                cell(
                                    '$d\n${[
                                      '一',
                                      '二',
                                      '三',
                                      '四',
                                      '五',
                                      '六',
                                      '日'
                                    ][DateTime(report.month.year, report.month.month, d).weekday - 1]}',
                                    44,
                                    header: true,
                                    weekend: DateTime(report.month.year,
                                                report.month.month, d)
                                            .weekday >=
                                        6),
                              for (final label in monthlyAttendanceStatistics)
                                cell(label, 80, header: true),
                            ]),
                            for (final row in report.rows)
                              Row(children: [
                                cell('', 48),
                                for (var d = 0; d < report.days; d++)
                                  cell(row.days[d].symbol, 44,
                                      weekend: DateTime(report.month.year,
                                                  report.month.month, d + 1)
                                              .weekday >=
                                          6,
                                      warning: row.days[d].needsReview,
                                      tooltip: row.days[d].description),
                                for (final value in row.statistics)
                                  cell(value, 80),
                              ]),
                          ])))),
        ]),
        SizedBox(height: ds.metric('spaceSmall')),
        Text('姓名固定在左側，向右捲動可查看整月與月底統計。',
            style: TextStyle(
                fontSize: ds.metric('labelSize'),
                color: ds.color('secondaryText'))),
      ]);
    });
  }
}
