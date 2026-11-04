import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../model/roster/monthly_attendance_report.dart';

/// Monochrome paper-template layout, independent of screen themes.
class MonthlyAttendancePdf {
  static Future<Uint8List> build(
      MonthlyAttendanceReport report, ByteData fontData) async {
    final font = pw.Font.ttf(fontData);
    final pdf = pw.Document(
        title: '${report.site.name} ${report.label}出席紀錄表',
        author: '黃絲帶學習成長系統',
        theme: pw.ThemeData.withFont(base: font, bold: font));
    final usable = PdfPageFormat.a4.landscape.width - 36;
    final dayWidth = (usable - 112 - 186) / report.days;
    final widths = <double>[
      22,
      66,
      24,
      ...List.filled(report.days, dayWidth),
      32,
      34,
      28,
      28,
      28,
      36
    ];
    const line = pw.BorderSide(width: .4, color: PdfColors.grey700);
    bool weekend(int d) =>
        DateTime(report.month.year, report.month.month, d).weekday >= 6;
    pw.Widget cell(String text, double width, double height,
            {bool shaded = false}) =>
        pw.Container(
            width: width,
            height: height,
            alignment: pw.Alignment.center,
            padding: const pw.EdgeInsets.symmetric(horizontal: 1),
            decoration: pw.BoxDecoration(
                color: shaded ? PdfColors.grey400 : PdfColors.white,
                border: const pw.Border(
                    top: line, left: line, right: line, bottom: line)),
            child: pw.Text(text,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8)));
    double rowHeight(MonthlyAttendanceRow row) =>
        ((row.name.runes.length / 7).ceil() * 10.0 + 4)
            .clamp(14.0, 140.0)
            .toDouble();
    final pages = <List<MonthlyAttendanceRow>>[];
    var current = <MonthlyAttendanceRow>[];
    var used = 0.0;
    for (final row in report.rows) {
      if (used + rowHeight(row) > 460 && current.isNotEmpty) {
        pages.add(current);
        current = [];
        used = 0;
      }
      current.add(row);
      used += rowHeight(row);
    }
    if (current.isNotEmpty || pages.isEmpty) pages.add(current);
    var offset = 0;
    for (var page = 0; page < pages.length; page++) {
      final rows = pages[page];
      final startIndex = offset;
      pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(18),
          build: (_) => pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    pw.Text('黃絲帶學習成長系統',
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 13)),
                    pw.SizedBox(height: 5),
                    pw.Text('${report.site.name}　${report.label} 出席紀錄表',
                        textAlign: pw.TextAlign.center,
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 7),
                    pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                              '${report.month.year} 年　${report.month.month} 月',
                              style: const pw.TextStyle(fontSize: 9)),
                          pw.Text('出席 ○　病假 ＋　事假 △　無故缺席 ×',
                              style: const pw.TextStyle(fontSize: 9)),
                        ]),
                    pw.SizedBox(height: 5),
                    pw.Container(
                        decoration: const pw.BoxDecoration(
                            border: pw.Border(top: line, left: line)),
                        child: pw.Column(children: [
                          pw.Row(children: [
                            for (var i = 0; i < 3; i++)
                              cell(['編號', '姓名', '年級'][i], widths[i], 30),
                            for (var d = 1; d <= report.days; d++)
                              pw.Column(children: [
                                cell('$d', dayWidth, 15),
                                cell(
                                    ['一', '二', '三', '四', '五', '六', '日'][
                                        DateTime(report.month.year,
                                                    report.month.month, d)
                                                .weekday -
                                            1],
                                    dayWidth,
                                    15,
                                    shaded: weekend(d)),
                              ]),
                            cell('應出席\n天數', 32, 30),
                            cell('實際出\n席天數', 34, 30),
                            pw.Column(children: [
                              cell('缺席統計', 84, 15),
                              pw.Row(children: [
                                for (final text in ['病假', '事假', '無故'])
                                  cell(text, 28, 15),
                              ])
                            ]),
                            cell('出席率', 36, 30),
                          ]),
                          for (var index = 0; index < rows.length; index++)
                            pw.Row(children: [
                              cell('${startIndex + index + 1}', 22,
                                  rowHeight(rows[index])),
                              cell(
                                  rows[index].name, 66, rowHeight(rows[index])),
                              cell('', 24, rowHeight(rows[index])),
                              for (var d = 0; d < report.days; d++)
                                cell(rows[index].days[d].symbol, dayWidth,
                                    rowHeight(rows[index]),
                                    shaded: weekend(d + 1)),
                              for (var i = 0; i < 6; i++)
                                cell(
                                    rows[index].statistics[i],
                                    widths[report.days + 3 + i],
                                    rowHeight(rows[index])),
                            ]),
                        ])),
                    if (pages.length > 1) ...[
                      pw.SizedBox(height: 5),
                      pw.Text('${page + 1} / ${pages.length}',
                          textAlign: pw.TextAlign.right,
                          style: const pw.TextStyle(fontSize: 7))
                    ],
                  ])));
      offset += rows.length;
    }
    return pdf.save();
  }
}
