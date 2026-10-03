import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_models.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_policy.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/student_history_service.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/attendance/attendance_record_card.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/roster/daily_roster_view.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/roster/performance_record_card.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/roster/record_text_field.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/roster/enrollment_fields.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/roster/enrollment_change_form.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/roster/attendance_statistics_card.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/roster/student_history_view.dart';
import '../gallery_environment.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/attendance_status.dart';

const rosterSites = [
  ClassSite('demo-a', '合成永安據點'),
  ClassSite('demo-b', '合成北方據點')
];
Widget _surface(WidgetBuilder builder) => ProductPreview(
    builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16), child: builder(context)));

@widgetbook.UseCase(name: 'Unmarked attendance', type: AttendanceRecordCard)
Widget attendanceUnmarked(BuildContext context) =>
    _surface((_) => AttendanceRecordCard.data(
        studentName: '合成新同學',
        status: null,
        notice: '入班日起列入名冊，尚未點名',
        onStatusChanged: (_) {}));
@widgetbook.UseCase(name: 'Readonly attendance', type: AttendanceRecordCard)
Widget attendanceReadonly(BuildContext context) =>
    _surface((_) => const AttendanceRecordCard.data(
        studentName: '合成歷史同學', status: null, notice: '歷史就讀期間待核對，暫不可編輯'));

Widget _performance(
    {bool disabled = false, bool assessed = false, bool long = false}) {
  var values = <String, dynamic>{
    if (assessed) 'performanceRating': 'excellent',
    if (assessed) 'mathPerformanceRating': 5,
    if (long) 'remarks': '合成的長評語，練習仔細描述孩子的學習過程。' * 12
  };
  return _surface((context) => StatefulBuilder(
      builder: (context, setState) => PerformanceRecordCard(
          studentName: long ? '這是一位姓名較長的合成同學・測試文字換行' : '合成小禾',
          values: values,
          notice: disabled ? '歷史資料待核對' : '修改先留在草稿，儲存後才更新獎勵',
          onChanged: disabled
              ? null
              : (field, value) =>
                  setState(() => values = {...values, field: value}))));
}

@widgetbook.UseCase(name: 'Unassessed performance', type: PerformanceRecordCard)
Widget performanceUnassessed(BuildContext context) => _performance();
@widgetbook.UseCase(name: 'Assessed performance', type: PerformanceRecordCard)
Widget performanceAssessed(BuildContext context) =>
    _performance(assessed: true);
@widgetbook.UseCase(name: 'Readonly performance', type: PerformanceRecordCard)
Widget performanceReadonly(BuildContext context) =>
    _performance(disabled: true, assessed: true);
@widgetbook.UseCase(name: 'Long performance notes', type: PerformanceRecordCard)
Widget performanceLong(BuildContext context) => _performance(long: true);

Widget _daily(String variant) => ProductPreview(
    builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: DailyRosterView(
            kind: variant == 'performance' ? 'performance' : 'attendance',
            dateLabel: '2026-10-02',
            summary: '名冊 3 位 · 已點名 1 · 未點名 2',
            sites: rosterSites,
            locationId: 'demo-a',
            loading: variant == 'loading',
            error: variant == 'error' ? '名冊尚未完整載入，請重試' : null,
            saveMessage: switch (variant) {
              'new-edits' => '整批儲存成功：已確認儲存 2 筆修改。\n儲存期間又有新修改尚未提交，請再次按「儲存修改」。',
              'rejected' =>
                '整批儲存失敗：所有修改仍保留。\n合成小葵：儲存失敗：目前沒有操作權限。你的修改仍保留，請聯絡管理者確認權限。',
              'unknown' =>
                '整批儲存結果尚未確認；所有修改仍保留，請重試確認同一筆交易。\n合成小葵：尚未確認是否儲存成功：未取得伺服器確認。修改仍保留，請確認網路後按「重試儲存」確認結果，勿重新建立相同紀錄。',
              'saved' => '整批儲存成功：已確認儲存 2 筆修改。',
              _ => null,
            },
            saveIncomplete:
                ['new-edits', 'rejected', 'unknown'].contains(variant),
            canSave: ['new-edits', 'rejected', 'unknown'].contains(variant),
            saving: variant == 'saving',
            rows: ['loading', 'error', 'empty'].contains(variant)
                ? []
                : [
                    const RosterRowViewData(
                        id: 'a', name: '合成小禾', values: {'status': 'attend'}),
                    RosterRowViewData(
                        id: 'b',
                        name: '合成小葵',
                        values: const {},
                        dirty: ['new-edits', 'rejected', 'unknown']
                            .contains(variant),
                        canResolveConflict: false,
                        canDiscard: variant != 'unknown',
                        error: variant == 'rejected'
                            ? '儲存失敗：目前沒有操作權限；所有修改仍保留'
                            : variant == 'unknown'
                                ? '尚未確認是否儲存成功，請重試儲存'
                                : null),
                    if (variant == 'orphan')
                      const RosterRowViewData(
                          id: 'old',
                          name: '合成歷史學生',
                          values: {},
                          enabled: false,
                          orphan: true,
                          notice: '歷史就讀關係待核對，不列正常名冊分母'),
                  ],
            onSave: () {},
            onSearch: (_) {},
            onPickDate: () {},
            onRetry: () {},
            onStatusFilter: (_) {},
            onLocationChanged: (_) {},
            onEdit: (_, __, ___) {},
            onDiscard: (_) {},
            onKeepLocal: (_) {})));
@widgetbook.UseCase(name: 'Daily attendance roster', type: DailyRosterView)
Widget dailyRosterReady(BuildContext context) => _daily('ready');
@widgetbook.UseCase(name: 'Daily performance roster', type: DailyRosterView)
Widget dailyRosterPerformance(BuildContext context) => _daily('performance');
@widgetbook.UseCase(name: 'Roster loading', type: DailyRosterView)
Widget dailyRosterLoading(BuildContext context) => _daily('loading');
@widgetbook.UseCase(name: 'Roster empty', type: DailyRosterView)
Widget dailyRosterEmpty(BuildContext context) => _daily('empty');
@widgetbook.UseCase(name: 'Roster error', type: DailyRosterView)
Widget dailyRosterError(BuildContext context) => _daily('error');
@widgetbook.UseCase(name: 'Roster saved with new edits', type: DailyRosterView)
Widget dailyRosterPendingEdits(BuildContext context) => _daily('new-edits');
@widgetbook.UseCase(name: 'Roster save rejected', type: DailyRosterView)
Widget dailyRosterRejected(BuildContext context) => _daily('rejected');
@widgetbook.UseCase(name: 'Roster save unconfirmed', type: DailyRosterView)
Widget dailyRosterUnconfirmed(BuildContext context) => _daily('unknown');
@widgetbook.UseCase(name: 'Roster save confirmed', type: DailyRosterView)
Widget dailyRosterSaved(BuildContext context) => _daily('saved');
@widgetbook.UseCase(name: 'Roster saving', type: DailyRosterView)
Widget dailyRosterSaving(BuildContext context) => _daily('saving');
@widgetbook.UseCase(name: 'Orphan history', type: DailyRosterView)
Widget dailyRosterOrphan(BuildContext context) => _daily('orphan');

@widgetbook.UseCase(name: 'Editable record text', type: RecordTextField)
Widget recordTextEditable(BuildContext context) => _surface(
    (_) => RecordTextField(value: '合成備註', label: '備註', onChanged: (_) {}));
@widgetbook.UseCase(name: 'Readonly record text', type: RecordTextField)
Widget recordTextReadonly(BuildContext context) =>
    _surface((_) => const RecordTextField(value: '合成備註', label: '備註'));
@widgetbook.UseCase(name: 'New enrollment fields', type: EnrollmentFields)
Widget enrollmentNew(BuildContext context) => _surface((_) => EnrollmentFields(
    sites: rosterSites,
    locationId: 'demo-a',
    locationName: '合成永安據點',
    dateLabel: '2026-10-02',
    creating: true,
    onLocation: (_) {},
    onDate: () {}));
@widgetbook.UseCase(name: 'Unknown enrollment start', type: EnrollmentFields)
Widget enrollmentUnknown(BuildContext context) =>
    _surface((_) => const EnrollmentFields(
        sites: rosterSites,
        locationId: 'demo-a',
        locationName: '合成永安據點',
        dateLabel: '2026-10-02',
        startKnown: false));
@widgetbook.UseCase(name: 'Enrollment saving', type: EnrollmentFields)
Widget enrollmentSaving(BuildContext context) =>
    _surface((_) => EnrollmentFields(
        sites: rosterSites,
        locationId: 'demo-a',
        locationName: '合成永安據點',
        dateLabel: '2026-10-02',
        creating: true,
        busy: true,
        onLocation: (_) {},
        onDate: () {}));
@widgetbook.UseCase(
    name: 'Transfer archive and correction', type: EnrollmentChangeForm)
Widget enrollmentChange(BuildContext context) => ProductPreview(
    builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: EnrollmentChangeForm(
            sites: rosterSites,
            currentLocationId: 'demo-a',
            periods: [
              Enrollment('e',
                  studentId: 's',
                  locationId: 'demo-a',
                  startDate: BusinessDate('2026-10-02'),
                  endDateExclusive: BusinessDate('9999-12-31'),
                  startKnown: false)
            ],
            onSubmit: (_) => previewAction(context, '合成就讀異動已確認'),
            onCancel: () => previewAction(context, '取消異動'))));

@widgetbook.UseCase(
    name: 'Final attendance rate', type: AttendanceStatisticsCard)
Widget statisticsFinal(BuildContext context) =>
    _surface((_) => const AttendanceStatisticsCard(
        statistics: AttendanceStatistics(12, 12, 9)));
@widgetbook.UseCase(
    name: 'Provisional attendance rate', type: AttendanceStatisticsCard)
Widget statisticsPending(BuildContext context) =>
    _surface((_) => const AttendanceStatisticsCard(
        statistics: AttendanceStatistics(12, 10, 8)));
@widgetbook.UseCase(
    name: 'Insufficient historical evidence', type: AttendanceStatisticsCard)
Widget statisticsUnknown(BuildContext context) =>
    _surface((_) => const AttendanceStatisticsCard(
        statistics: AttendanceStatistics(0, 0, 0),
        unknownEnrollmentCoverage: true,
        fromCache: true));

StudentHistory historyFixture() => StudentHistory(
    studentId: 's',
    name: '合成小禾',
    from: BusinessDate('2026-10-01'),
    to: BusinessDate('2026-10-31'),
    sites: rosterSites,
    enrollments: [
      Enrollment('e',
          studentId: 's',
          locationId: 'demo-a',
          startDate: BusinessDate('2026-10-01'),
          endDateExclusive: BusinessDate('9999-12-31'))
    ],
    attendance: const [],
    performance: [
      DailyRecord('performance',
          studentId: 's',
          locationId: 'demo-a',
          date: BusinessDate('2026-10-02'),
          values: {
            'performanceRating': 'good',
            'remarks': '合成評語',
            'mathPerformanceRating': 5
          })
    ],
    statistics: const AttendanceStatistics(12, 10, 8),
    fromCache: false,
    unknownEnrollmentCoverage: false);
Widget _history(
        {bool loading = false, bool empty = false, bool error = false}) =>
    ProductPreview(
        builder: (_) => Padding(
            padding: const EdgeInsets.all(16),
            child: StudentHistoryView(
                monthLabel: '2026-10',
                history: loading || error
                    ? null
                    : empty
                        ? StudentHistory(
                            studentId: 's',
                            name: '合成小禾',
                            from: BusinessDate('2026-10-01'),
                            to: BusinessDate('2026-10-31'),
                            sites: rosterSites,
                            enrollments: const [],
                            attendance: const [],
                            performance: const [],
                            statistics: const AttendanceStatistics(0, 0, 0),
                            fromCache: false,
                            unknownEnrollmentCoverage: false)
                        : historyFixture(),
                loading: loading,
                error: error ? '載入失敗，請重試' : null,
                onPrevious: () {},
                onNext: () {},
                onPickMonth: () {},
                onRetry: () {},
                onOpenDay: (_) {})));
@widgetbook.UseCase(
    name: 'Monthly history and growth', type: StudentHistoryView)
Widget historyReady(BuildContext context) => _history();
@widgetbook.UseCase(name: 'History loading', type: StudentHistoryView)
Widget historyLoading(BuildContext context) => _history(loading: true);
@widgetbook.UseCase(name: 'History error', type: StudentHistoryView)
Widget historyError(BuildContext context) => _history(error: true);

@widgetbook.UseCase(name: 'History empty', type: StudentHistoryView)
Widget historyEmpty(BuildContext context) => _history(empty: true);

@widgetbook.UseCase(name: 'Attendance status chips', type: AttendanceStatusChip)
Widget attendanceChips(BuildContext context) =>
    _surface((_) => Wrap(spacing: 12, runSpacing: 12, children: [
          const AttendanceStatusChip(null),
          for (final status in AttendanceStatus.values)
            AttendanceStatusChip(status)
        ]));
