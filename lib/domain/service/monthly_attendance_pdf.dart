import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../model/roster/monthly_attendance_report.dart';

/// Print styling is intentionally monochrome and independent of screen themes.
class MonthlyAttendancePdf {
  static Future<Uint8List> build(
      MonthlyAttendanceReport report, ByteData fontData) async {
    final font = pw.Font.ttf(fontData);
    final pdf = pw.Document(
        title: '${report.site.name} ${report.label}出席紀錄表',
        author: '黃絲帶學習成長系統',
        theme: pw.ThemeData.withFont(base: font, bold: font));
    final widths = <int, pw.TableColumnWidth>{
      0: const pw.FixedColumnWidth(22),
      1: const pw.FixedColumnWidth(62),
      2: const pw.FixedColumnWidth(24),
      for (var i = 0; i < report.days; i++)
        i + 3: const pw.FixedColumnWidth(14),
      for (var i = 0; i < 10; i++)
        i + 3 + report.days: pw.FixedColumnWidth(i == 9 ? 38 : 27)
    };
    pw.Widget cell(String text,
            {bool header = false,
            bool weekend = false,
            bool name = false,
            double height = 12.5}) =>
        pw.Container(
            height: header ? 30 : height,
            alignment: pw.Alignment.center,
            padding: const pw.EdgeInsets.symmetric(horizontal: 1),
            color: weekend
                ? PdfColors.grey300
                : header
                    ? PdfColors.grey100
                    : null,
            child: pw.Text(text,
                textAlign: pw.TextAlign.center,
                maxLines: name
                    ? null
                    : header
                        ? 2
                        : 1,
                style: pw.TextStyle(fontSize: name ? 7 : 6.5)));
    double rowHeight(MonthlyAttendanceRow row) =>
        ((row.name.runes.length / 7).ceil() * 8.5 + 2)
            .clamp(12.5, 160)
            .toDouble();
    final pages = <List<MonthlyAttendanceRow>>[];
    var current = <MonthlyAttendanceRow>[];
    var used = 0.0;
    for (final row in report.rows) {
      if (used + rowHeight(row) > 400 && current.isNotEmpty) {
        pages.add(current);
        current = [];
        used = 0;
      }
      current.add(row);
      used += rowHeight(row);
    }
    if (current.isNotEmpty || pages.isEmpty) pages.add(current);
    final totalPages = pages.length;
    var offset = 0;
    for (var page = 0; page < totalPages; page++) {
      final rows = pages[page];
      final startIndex = offset;
      pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.fromLTRB(18, 18, 18, 15),
          build: (_) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text('黃絲帶學習成長系統',
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 15)),
                    pw.SizedBox(height: 5),
                    pw.Text('${report.site.name}　${report.label} 出席紀錄表',
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 8),
                    pw.Text(monthlyAttendanceLegend,
                        style: const pw.TextStyle(fontSize: 7)),
                    pw.SizedBox(height: 6),
                    pw.Table(
                        columnWidths: widths,
                        border: pw.TableBorder.all(
                            width: .35, color: PdfColors.grey600),
                        children: [
                          pw.TableRow(children: [
                            for (final label in ['編號', '姓名', '年級'])
                              cell(label, header: true),
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
                                  header: true,
                                  weekend: DateTime(report.month.year,
                                              report.month.month, d)
                                          .weekday >=
                                      6),
                            for (final label in monthlyAttendanceStatistics)
                              cell(
                                  label.length > 3
                                      ? '${label.substring(0, 2)}\n${label.substring(2)}'
                                      : label,
                                  header: true),
                          ]),
                          for (var index = 0; index < rows.length; index++)
                            pw.TableRow(children: [
                              cell('${startIndex + index + 1}',
                                  height: rowHeight(rows[index])),
                              cell(rows[index].name,
                                  name: true, height: rowHeight(rows[index])),
                              cell('', height: rowHeight(rows[index])),
                              for (var d = 0; d < report.days; d++)
                                cell(rows[index].days[d].symbol,
                                    height: rowHeight(rows[index]),
                                    weekend: DateTime(report.month.year,
                                                report.month.month, d + 1)
                                            .weekday >=
                                        6),
                              for (final value in rows[index].statistics)
                                cell(value, height: rowHeight(rows[index])),
                            ]),
                        ]),
                    pw.SizedBox(height: 7),
                    for (final note in monthlyAttendanceNotes)
                      pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 3),
                          child: pw.Text(note,
                              style: const pw.TextStyle(fontSize: 6.5))),
                    pw.Spacer(),
                    pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                              '${report.rows.length} 位學生 · ${report.recordCount} 筆紀錄 · ${report.pending} 筆待核對${report.fromCache ? ' · 離線資料' : ''}',
                              style: const pw.TextStyle(fontSize: 6.5)),
                          pw.Text('${page + 1} / $totalPages',
                              style: const pw.TextStyle(fontSize: 6.5)),
                        ]),
                  ])));
      offset += rows.length;
    }
    return pdf.save();
  }
}
