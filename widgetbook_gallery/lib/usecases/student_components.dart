import 'dart:async';
import 'package:yellow_ribbon_study_growing_system/main/components/login/login_submit_button.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/privacy/privacy_policy_view.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/privacy_policy.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/components/system_page.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/components/system_section_card.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/student_info/student_identity_card.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/student_info/info_card_layout.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/avatar/student_avatar.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_info_page/student_directory_view.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_detail_page/student_profile_overview.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_cubit/student_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_activity_cubit/student_activity_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_performance/student_daily_performance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/performance_rating.dart';
import 'package:yellow_ribbon_study_growing_system/domain/service/storage_service.dart';
import '../gallery_environment.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/components/system_page_header.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yb_dropdown_menu/class_location_filter_field.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/components/system_pill_segment.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/attendance_status.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_attendance/student_daily_attendance_info.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/attendance/attendance_record_card.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/attendance/attendance_summary_bar.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/student_info/student_growing_report_card.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yellow_ribbon/yellow_ribbon_count_badge.dart';

@widgetbook.UseCase(name: 'Login action', type: LoginSubmitButton)
Widget loginAction(BuildContext context) => ProductPreview(
    builder: (context) => Center(
        child: LoginSubmitButton(
            onPressed: () => previewAction(context, '登入展示，不連線'))));

@widgetbook.UseCase(name: 'Submitting login', type: LoginSubmitButton)
Widget submittingLogin(BuildContext context) => ProductPreview(
    builder: (_) => const Center(
        child: LoginSubmitButton(onPressed: null, submitting: true)));

@widgetbook.UseCase(name: 'Disabled login', type: LoginSubmitButton)
Widget disabledLogin(BuildContext context) => ProductPreview(
    builder: (_) => const Center(child: LoginSubmitButton(onPressed: null)));

@widgetbook.UseCase(name: 'Full offline policy', type: PrivacyPolicyView)
Widget privacyPolicy(BuildContext context) => ProductPreview(
    builder: (context) => PrivacyPolicyView(
        updated: privacyPolicyUpdated,
        sections: privacyPolicySections,
        scaffoldKey: GlobalKey<ScaffoldState>(),
        onBack: () => previewAction(context, '返回原畫面')));

@widgetbook.UseCase(name: 'Policy action', type: PrivacyPolicyButton)
Widget privacyAction(BuildContext context) => ProductPreview(
    builder: (context) => Center(
        child: PrivacyPolicyButton(
            onPressed: () => previewAction(context, '開啟隱私權政策'))));

@widgetbook.UseCase(name: 'Disabled policy action', type: PrivacyPolicyButton)
Widget disabledPrivacyAction(BuildContext context) => ProductPreview(
    builder: (context) =>
        const Center(child: PrivacyPolicyButton(onPressed: null)));

@widgetbook.UseCase(
    name: 'Zero and earned ribbons', type: YellowRibbonCountBadge)
Widget ribbonBadges(BuildContext context) => ProductPreview(
    builder: (context) => Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('每一份努力，都值得被看見。',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 24),
                    const SystemSectionCard(
                        title: '黃絲帶紀錄',
                        icon: Icons.workspace_premium_outlined,
                        child: Wrap(spacing: 16, runSpacing: 16, children: [
                          YellowRibbonCountBadge(count: 0),
                          YellowRibbonCountBadge(count: 12),
                          YellowRibbonCountBadge(count: 128),
                        ])),
                    const SizedBox(height: 20),
                    const SystemSectionCard(
                        title: '學生頭像',
                        icon: Icons.face_outlined,
                        child: Center(
                            child: Wrap(spacing: 48, runSpacing: 24, children: [
                          StudentAvatar(
                              gender: '男', size: 112, yellowRibbonCount: 0),
                          StudentAvatar(
                              gender: '女', size: 112, yellowRibbonCount: 12),
                        ]))),
                  ]),
            ),
          ),
        ));

// Synthetic fixtures only; this gallery never initializes Firebase.
final demoStudents = [
  StudentDetail.empty().copyWith(
      id: 'demo-1',
      name: '林小禾',
      school: '向陽國小',
      gender: '男',
      guardianName: '林家長',
      motto: '每天進步一點點。'),
  StudentDetail.empty()
      .copyWith(id: 'demo-2', name: '陳小葵', school: '向陽國小', gender: '女'),
  StudentDetail.empty().copyWith(
      id: 'demo-3',
      name: '王小宇',
      school: '樹林國中',
      classLocation: ClassLocation.values.last.name),
];
StudentActivityState demoActivity() => StudentActivityState(records: [
      StudentDailyPerformanceRecord(
          'demo-1', '林小禾', ClassLocation.values.first, PerformanceRating.good,
          recordDate: DateTime(2026, 9, 17), remarks: '主動參與討論，也願意協助同學。')
    ]);
StudentIdentityCard demoCard(
        BuildContext context, StudentDetail student, bool compact) =>
    StudentIdentityCard(
        student: student,
        compact: compact,
        ribbonCount: 8,
        onOpen: () => previewAction(context, '查看資料'),
        onEdit: () => previewAction(context, '編輯資料'),
        onDelete: () => previewAction(context, '展示模式，不會刪除資料'));

Widget cardCase({bool compact = false, bool longText = false}) =>
    ProductPreview(
        builder: (context) => Center(
            child: SizedBox(
                width: compact ? 1000 : 400,
                height: compact ? null : 260,
                child: demoCard(
                    context,
                    longText
                        ? demoStudents.first.copyWith(
                            name: '很長姓名的示範學生・阿布', school: '這是一所名稱很長的實驗教育學校')
                        : demoStudents.first,
                    compact))));
@widgetbook.UseCase(name: 'Card', type: StudentIdentityCard)
Widget identityCard(BuildContext context) => cardCase();
@widgetbook.UseCase(name: 'List row', type: StudentIdentityCard)
Widget identityRow(BuildContext context) => cardCase(compact: true);
@widgetbook.UseCase(name: 'Long content', type: StudentIdentityCard)
Widget identityLong(BuildContext context) => cardCase(longText: true);

Widget directoryCase(StudentsState state) => ProductPreview(
    builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: StudentDirectoryView(
            state: state,
            onCreate: () => previewAction(context, '新增學生'),
            onRetry: () => previewAction(context, '已觸發重新載入'),
            itemBuilder: (s, c) => demoCard(context, s, c))));
@widgetbook.UseCase(name: 'Search and view switch', type: StudentDirectoryView)
Widget directoryReady(BuildContext context) =>
    directoryCase(StudentsState(demoStudents));
@widgetbook.UseCase(name: 'Loading', type: StudentDirectoryView)
Widget directoryLoading(BuildContext context) =>
    directoryCase(StudentsState([], isLoading: true));
@widgetbook.UseCase(name: 'Empty', type: StudentDirectoryView)
Widget directoryEmpty(BuildContext context) => directoryCase(StudentsState([]));
@widgetbook.UseCase(name: 'Error and retry', type: StudentDirectoryView)
Widget directoryError(BuildContext context) =>
    directoryCase(StudentsState([], errorMessage: '學生資料載入失敗，請重試。'));

Widget profileContent(BuildContext context, StudentDetail student,
        StudentActivityState activity) =>
    StudentProfileOverview(
        student: student,
        activity: activity,
        ribbonCount: 8,
        onEdit: () => previewAction(context, '編輯資料'),
        onHistory: () => previewAction(context, '查看完整紀錄'),
        onRetry: () => previewAction(context, '已觸發重新載入'),
        attachment: const SystemSectionCard(
            title: '個人檔案',
            icon: Icons.folder_open_outlined,
            child: Text('尚未上傳附件')));
// These production-component cases also preview primaryText/secondaryText
// changes using ProductPreview's shared catalog and Light/Dark controls.
Widget profileCase(StudentActivityState activity, {bool longText = false}) =>
    ProductPreview(
        builder: (context) => Padding(
            padding: const EdgeInsets.all(16),
            child: profileContent(
                context,
                longText
                    ? demoStudents.first
                        .copyWith(motto: '用自己的步伐學習，相信每一次嘗試都能帶來新的發現。' * 4)
                    : demoStudents.first,
                activity)));
@widgetbook.UseCase(name: 'With activity', type: StudentProfileOverview)
Widget profileReady(BuildContext context) => profileCase(demoActivity());
@widgetbook.UseCase(name: 'Empty activity', type: StudentProfileOverview)
Widget profileEmpty(BuildContext context) =>
    profileCase(const StudentActivityState());
@widgetbook.UseCase(name: 'Loading activity', type: StudentProfileOverview)
Widget profileLoading(BuildContext context) =>
    profileCase(const StudentActivityState(loading: true));
@widgetbook.UseCase(name: 'Activity error', type: StudentProfileOverview)
Widget profileError(BuildContext context) =>
    profileCase(const StudentActivityState(failed: true));
@widgetbook.UseCase(name: 'Long motto', type: StudentProfileOverview)
Widget profileLong(BuildContext context) =>
    profileCase(demoActivity(), longText: true);

@widgetbook.UseCase(name: 'Section and actions', type: SystemSectionCard)
Widget sectionCard(BuildContext context) => ProductPreview(
    builder: (context) => Center(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child: SystemSectionCard(
                title: '基本資料',
                icon: Icons.description_outlined,
                action: TextButton(
                    onPressed: () => previewAction(context, '編輯'),
                    child: const Text('編輯')),
                child: const Text('同一份區塊元件，用於詳情、表單與附件。')))));
@widgetbook.UseCase(
    name: 'Responsive form section', type: InfoCardLayoutWith2Column)
Widget formSection(BuildContext context) => ProductPreview(
    builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: InfoCardLayoutWith2Column(title: '基本資料', columns1: [
          TextFormField(
              initialValue: '林小禾',
              decoration: const InputDecoration(labelText: '學生姓名')),
          TextFormField(
              initialValue: '向陽國小',
              decoration: const InputDecoration(labelText: '學校'))
        ], columns2: [
          TextFormField(
              initialValue: '林家長',
              decoration: const InputDecoration(labelText: '監護人')),
          TextFormField(
              decoration: const InputDecoration(
                  labelText: '聯絡電話', errorText: '請輸入有效的聯絡電話'))
        ])));
@widgetbook.UseCase(name: 'Default boy and girl', type: StudentAvatar)
Widget avatarDefaults(BuildContext context) => ProductPreview(
    builder: (_) => const Center(
            child: Wrap(spacing: 24, children: [
          StudentAvatar(gender: '男'),
          StudentAvatar(gender: '女'),
          StudentAvatar()
        ])));

class DemoAvatarStorage implements StorageService {
  DemoAvatarStorage(this.loading);
  final bool loading;
  @override
  Future<String?> getAvatarUrl(String? fileName) =>
      loading ? Completer<String?>().future : Future.value(null);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@widgetbook.UseCase(name: 'Loading photo', type: StudentAvatar)
Widget avatarLoading(BuildContext context) => ProductPreview(
    builder: (_) => Center(
        child: StudentAvatar(
            avatarFileName: 'demo-loading',
            gender: '男',
            storageService: DemoAvatarStorage(true))));
@widgetbook.UseCase(name: 'Missing photo and retry', type: StudentAvatar)
Widget avatarError(BuildContext context) => ProductPreview(
    builder: (_) => Center(
        child: StudentAvatar(
            avatarFileName: 'demo-missing',
            gender: '女',
            storageService: DemoAvatarStorage(false))));
@widgetbook.UseCase(name: 'Directory to profile journey', type: SystemPage)
Widget studentJourney(BuildContext context) =>
    ProductPreview(builder: (_) => const _Journey());

class _Journey extends StatefulWidget {
  const _Journey();
  @override
  State<_Journey> createState() => _JourneyState();
}

class _JourneyState extends State<_Journey> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  StudentDetail? selected;
  @override
  Widget build(BuildContext context) => SystemPage(
      title: '學生資料',
      scaffoldKey: scaffoldKey,
      onBack: () => setState(() => selected = null),
      child: selected != null
          ? profileContent(context, selected!, demoActivity())
          : StudentDirectoryView(
              state: StudentsState(demoStudents),
              onCreate: () => previewAction(context, '新增學生'),
              onRetry: () {},
              itemBuilder: (s, c) => StudentIdentityCard(
                  student: s,
                  compact: c,
                  ribbonCount: 8,
                  onOpen: () => setState(() => selected = s),
                  onEdit: () => previewAction(context, '編輯資料'),
                  onDelete: () => previewAction(context, '展示模式，不會刪除資料'))));
}

// ---- Pill segment, attendance and report rows (synthetic fixtures only) ----

@widgetbook.UseCase(name: 'View switch', type: SystemPillSegment)
Widget pillViewSwitch(BuildContext context) =>
    ProductPreview(builder: (_) => const Center(child: _PillSwitchDemo()));

class _PillSwitchDemo extends StatefulWidget {
  const _PillSwitchDemo();
  @override
  State<_PillSwitchDemo> createState() => _PillSwitchDemoState();
}

class _PillSwitchDemoState extends State<_PillSwitchDemo> {
  bool list = false;
  @override
  Widget build(BuildContext context) => SystemPillSegment<bool>(
      selected: list,
      onChanged: (value) => setState(() => list = value),
      options: const [
        SystemPillOption(
            value: false, label: '卡片', icon: Icons.grid_view_rounded),
        SystemPillOption(
            value: true, label: '列表', icon: Icons.view_list_rounded),
      ]);
}

@widgetbook.UseCase(name: 'Status tones', type: SystemPillSegment)
Widget pillStatusTones(BuildContext context) => ProductPreview(
    builder: (_) => Center(
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: SystemPillSegment<AttendanceStatus>(
                dense: true,
                selected: AttendanceStatus.leave,
                onChanged: (_) {},
                options: AttendanceRecordCard.statusOptions))));

@widgetbook.UseCase(name: 'Disabled pills', type: SystemPillSegment)
Widget pillDisabled(BuildContext context) => ProductPreview(
    builder: (_) => Center(
        child: SystemPillSegment<AttendanceStatus>(
            dense: true,
            selected: AttendanceStatus.attend,
            onChanged: null,
            options: AttendanceRecordCard.statusOptions)));

StudentDailyAttendanceRecord demoAttendance(String name, AttendanceStatus s,
        {String reason = ''}) =>
    StudentDailyAttendanceRecord(
        'demo-$name', name, ClassLocation.values.first, s,
        leaveReason: reason);

Widget attendanceCase(StudentDailyAttendanceRecord record, double width) =>
    ProductPreview(
        builder: (_) => Center(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: SizedBox(
                    width: width,
                    child: AttendanceRecordCard(record,
                        attendStatusNotifier:
                            record.attendanceStatusNotifier)))));

@widgetbook.UseCase(name: 'Present', type: AttendanceRecordCard)
Widget attendancePresent(BuildContext context) =>
    attendanceCase(demoAttendance('林小禾', AttendanceStatus.attend), 480);
@widgetbook.UseCase(name: 'Leave with reason', type: AttendanceRecordCard)
Widget attendanceLeave(BuildContext context) => attendanceCase(
    demoAttendance('陳小葵', AttendanceStatus.leave, reason: '家庭活動'), 480);
@widgetbook.UseCase(name: 'Long name in split view', type: AttendanceRecordCard)
Widget attendanceNarrow(BuildContext context) => attendanceCase(
    demoAttendance('很長姓名的示範學生・阿布', AttendanceStatus.late), 300);

@widgetbook.UseCase(name: 'Mixed statuses', type: AttendanceSummaryBar)
Widget attendanceSummary(BuildContext context) => ProductPreview(
    builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: AttendanceSummaryBar(
            dateLabel: '2026/09/26',
            locationLabel: ClassLocation.values.first.name,
            records: [
              demoAttendance('林小禾', AttendanceStatus.attend),
              demoAttendance('陳小葵', AttendanceStatus.leave),
              demoAttendance('王小宇', AttendanceStatus.late),
              demoAttendance('李小晴', AttendanceStatus.absent),
            ])));

@widgetbook.UseCase(name: 'Report rows', type: StudentGrowingReportCard)
Widget growingReportRows(BuildContext context) => ProductPreview(
    builder: (context) => Center(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
                width: 520,
                child: Column(children: [
                  for (final s in demoStudents) ...[
                    StudentGrowingReportCard(
                        student: s,
                        onOpen: () => previewAction(context, '查看個人表現')),
                    const SizedBox(height: 16),
                  ]
                ])))));
// ---- Shared page header and info bar (synthetic fixtures only) ----

@widgetbook.UseCase(
    name: 'Header with action and filters', type: SystemPageHeader)
Widget pageHeaderFull(BuildContext context) => ProductPreview(
    builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: SystemPageHeader(
            title: '今日點名',
            subtitle: '點選狀態即可記錄，離開時自動儲存。',
            action: ElevatedButton.icon(
                onPressed: () => previewAction(context, '儲存（展示）'),
                icon: const Icon(Icons.save),
                label: const Text('儲存')),
            filters: [
              ClassLocationFilterField(
                  notifier: ValueNotifier(ClassLocation.values.first)),
              const TextField(
                  decoration: InputDecoration(
                      hintText: '搜尋學生姓名',
                      prefixIcon: Icon(Icons.search_rounded))),
            ])));

@widgetbook.UseCase(name: 'Header without filters', type: SystemPageHeader)
Widget pageHeaderPlain(BuildContext context) => ProductPreview(
    builder: (context) => const Padding(
        padding: EdgeInsets.all(16),
        child: SystemPageHeader(
            title: '成長報告', subtitle: '選擇學生，查看歷次表現與成長紀錄。')));

@widgetbook.UseCase(name: 'Scope and trailing control', type: SystemPageInfoBar)
Widget pageInfoBar(BuildContext context) => ProductPreview(
    builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: SystemPageInfoBar(
            label: '${ClassLocation.values.first.name}  ·  27 位學生',
            trailing: SystemPillSegment<bool>(
                dense: true,
                selected: false,
                onChanged: (_) {},
                options: const [
                  SystemPillOption(
                      value: false,
                      label: '卡片',
                      icon: Icons.grid_view_rounded),
                  SystemPillOption(
                      value: true,
                      label: '列表',
                      icon: Icons.view_list_rounded),
                ]))));

@widgetbook.UseCase(
    name: 'Location filter in header', type: ClassLocationFilterField)
Widget locationFilter(BuildContext context) => ProductPreview(
    builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: SystemPageHeader(title: '篩選', filters: [
          ClassLocationFilterField(
              notifier: ValueNotifier(ClassLocation.values.first)),
        ])));
