import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/components/system_page_header.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_performance_cubit/student_performance_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/performance_rating.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_performance/student_daily_performance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_performance_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/utils/date_formatter.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/rating_scale/five_point_rating_scale.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yb_dropdown_menu/month_filter_dropdown_menu.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/components/system_page.dart';

class StudentHistoryPerformancePageWidget extends StatefulWidget {
  final StudentPerformanceCubit studentPerformanceCubit;
  final String studentId;

  const StudentHistoryPerformancePageWidget({
    Key? key,
    required this.studentPerformanceCubit,
    required this.studentId,
  }) : super(key: key);

  /// 从路由参数创建
  factory StudentHistoryPerformancePageWidget.fromParams(
      Map<String, String> pathParameters) {
    final studentId = pathParameters['studentId'] ?? '';
    return StudentHistoryPerformancePageWidget.withStudentId(studentId);
  }

  /// 使用学生ID创建
  factory StudentHistoryPerformancePageWidget.withStudentId(String studentId) {
    final cubit = StudentPerformanceCubit(
      StudentPerformanceState('', [], Operate.view),
      GetIt.I<DailyPerformanceRepo>(),
    );
    return StudentHistoryPerformancePageWidget(
      studentPerformanceCubit: cubit,
      studentId: studentId,
    );
  }

  @override
  State<StudentHistoryPerformancePageWidget> createState() =>
      _StudentHistoryPerformancePageWidgetState();
}

class _StudentHistoryPerformancePageWidgetState
    extends State<StudentHistoryPerformancePageWidget> {
  late StudentPerformanceCubit _model;
  // 月份筛选
  final ValueNotifier<DateTime?> _monthFilterNotifier =
      ValueNotifier<DateTime?>(null);

  @override
  void initState() {
    super.initState();
    _model = widget.studentPerformanceCubit;

    // 加载学生表现记录
    if (widget.studentId.isNotEmpty) {
      _model.load(widget.studentId);
    }

    // 添加月份筛选监听
    _monthFilterNotifier.addListener(_onMonthFilterChanged);
  }

  @override
  void dispose() {
    _monthFilterNotifier.removeListener(_onMonthFilterChanged);
    _monthFilterNotifier.dispose();
    super.dispose();
  }

  // 月份筛选变化时触发重建
  void _onMonthFilterChanged() {
    // 强制重新构建页面
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return BlocProvider(
      create: (context) => _model,
      child: SystemPage(
        scaffoldKey: scaffoldKey,
        title: '歷史表現',
        child: BlocBuilder<StudentPerformanceCubit, StudentPerformanceState>(
          builder: (context, state) {
            if (state.studentId.isEmpty && widget.studentId.isNotEmpty) {
              // 正在加载数据
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            // 获取日期范围
            final dateRange = _getDateRange(state.records);

            // 筛选记录
            final filteredRecords = _filterRecordsByMonth(state.records);
            final studentName = state.studentDetail?.name ??
                (state.records.isNotEmpty ? state.records.first.name : '學生');

            // 與其他頁一致：共用頁首（標題、篩選）＋資訊列，再接紀錄內容。
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SystemPageHeader(
                  title: studentName,
                  subtitle: '歷次表現紀錄，依日期由新到舊排列。',
                  filters: [
                    MonthFilterDropdownMenu(
                      monthFilterNotifier: _monthFilterNotifier,
                      earliestDate: dateRange.earliest,
                      latestDate: dateRange.latest,
                      labelPrefix: '月份',
                    ),
                  ],
                ),
                SystemPageInfoBar(label: '共 ${filteredRecords.length} 筆紀錄'),
                // 记录内容
                Expanded(
                  child: StudentHistoryPerformanceMainSection(
                    key: ValueKey(_monthFilterNotifier.value), // 添加key以确保切换时重建
                    studentId: state.studentId,
                    records: filteredRecords,
                    studentDetail: state.studentDetail,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // 获取记录的日期范围
  ({DateTime earliest, DateTime latest}) _getDateRange(
      List<StudentDailyPerformanceRecord> records) {
    if (records.isEmpty) {
      final now = DateTime.now();
      return (earliest: now, latest: now);
    }

    DateTime earliest = records.first.recordDate;
    DateTime latest = records.first.recordDate;

    for (var record in records) {
      if (record.recordDate.isBefore(earliest)) {
        earliest = record.recordDate;
      }
      if (record.recordDate.isAfter(latest)) {
        latest = record.recordDate;
      }
    }

    return (earliest: earliest, latest: latest);
  }

  // 按月份筛选记录
  List<StudentDailyPerformanceRecord> _filterRecordsByMonth(
      List<StudentDailyPerformanceRecord> records) {
    // 强制刷新记录
    final selectedMonth = _monthFilterNotifier.value;

    if (selectedMonth == null) {
      // 不筛选，返回所有记录（按日期从新到旧排序）
      final sortedRecords = _sortRecordsByDate(records);
      return sortedRecords;
    }

    // 获取选中月份的年和月
    final selectedYear = selectedMonth.year;
    final selectedMonthValue = selectedMonth.month;

    // 筛选该月的记录
    final filteredRecords = records.where((record) {
      return record.recordDate.year == selectedYear &&
          record.recordDate.month == selectedMonthValue;
    }).toList();

    // 按日期从新到旧排序
    final sortedRecords = _sortRecordsByDate(filteredRecords);
    return sortedRecords;
  }

  // 按日期从新到旧排序记录
  List<StudentDailyPerformanceRecord> _sortRecordsByDate(
      List<StudentDailyPerformanceRecord> records) {
    final sortedRecords = List<StudentDailyPerformanceRecord>.from(records);
    sortedRecords.sort((a, b) => b.recordDate.compareTo(a.recordDate));
    return sortedRecords;
  }
}

/// 历史表现主要内容区域
///
/// 依 docs/design-guideline.md：頁首已顯示學生與筆數，這裡直接列白色紀錄卡；
/// 顏色只用 SystemTheme 語意 token，狀態同時以文字表達。
class StudentHistoryPerformanceMainSection extends StatelessWidget {
  final String studentId;
  final List<StudentDailyPerformanceRecord> records;
  final dynamic studentDetail;

  const StudentHistoryPerformanceMainSection({
    Key? key,
    required this.studentId,
    required this.records,
    this.studentDetail,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    final gap = ds.metric('spaceMedium');

    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(gap),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                    color: ds.surfaceTone(100), shape: BoxShape.circle),
                child: Icon(Icons.event_note_rounded,
                    size: 44, color: ds.brandTone(700))),
            const SizedBox(height: 16),
            Text('這段期間沒有表現紀錄，請切換其他月份。',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: ds.metric('bodySize'),
                    color: ds.color('secondaryText'))),
          ]),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(bottom: gap),
      itemCount: records.length,
      separatorBuilder: (_, __) => SizedBox(height: gap),
      itemBuilder: (context, index) =>
          _buildPerformanceCard(context, records[index]),
    );
  }

  Widget _buildPerformanceCard(
      BuildContext context, StudentDailyPerformanceRecord record) {
    final ds = SystemTheme.of(context);
    final gap = ds.metric('spaceMedium');
    final ratings = [
      ('上課表現', record.classPerformanceRatingNotifier.value),
      ('數學成績', record.mathPerformanceRatingNotifier.value),
      ('國文成績', record.chinesePerformanceRatingNotifier.value),
      ('英文成績', record.englishPerformanceRatingNotifier.value),
      ('社會成績', record.socialPerformanceRatingNotifier.value),
    ];
    final rating = record.performanceRatingNotifier.value;
    final ratingTone = _ratingToneKey(rating);
    final remarks = record.remarksNotifier.value.trim();

    return Container(
      padding: EdgeInsets.all(gap),
      decoration: ds.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 日期與上課表現評級
          Row(children: [
            Icon(Icons.event_rounded, size: 20, color: ds.brandTone(700)),
            SizedBox(width: gap / 2),
            Expanded(
                child: Text(DateFormatter.formatToYYYYMMDD(record.recordDate),
                    style: TextStyle(
                        fontSize: ds.metric('bodySize') + 2,
                        fontWeight: FontWeight.w700,
                        color: ds.color('primaryText')))),
            _chip(context, '上課表現：${rating.label}',
                background: ds.statusSurface(ratingTone),
                foreground: ds.color(ratingTone)),
          ]),
          Divider(
              height: gap * 1.5, color: ds.color('border').withOpacity(.35)),

          // 五度量表（唯讀）：寬版兩欄、窄版一欄
          LayoutBuilder(builder: (context, box) {
            final columns = box.maxWidth >= 560 ? 2 : 1;
            final width = (box.maxWidth - gap * (columns - 1)) / columns;
            return Wrap(spacing: gap, runSpacing: gap / 2, children: [
              for (final (title, value) in ratings)
                SizedBox(
                    width: width,
                    child: FivePointRatingScale(
                        value: value, isEditable: false, title: title)),
            ]);
          }),
          SizedBox(height: gap),

          // 作業與小幫手：文字＋顏色同時表達
          Wrap(spacing: gap / 2, runSpacing: gap / 2, children: [
            _chip(context, record.homeworkCompleted ? '已完成作業' : '未完成作業',
                icon: record.homeworkCompleted
                    ? Icons.assignment_turned_in_rounded
                    : Icons.assignment_late_rounded,
                background: record.homeworkCompleted
                    ? ds.statusSurface('success')
                    : ds.color('secondaryBackground'),
                foreground: record.homeworkCompleted
                    ? ds.color('success')
                    : ds.color('secondaryText')),
            if (record.isHelper)
              _chip(context, '小幫手',
                  icon: Icons.emoji_people_rounded,
                  background: ds.surfaceTone(100),
                  foreground: ds.brandTone(700)),
          ]),
          SizedBox(height: gap),

          // 表現描述
          Text('表現描述',
              style: TextStyle(
                  fontSize: ds.metric('labelSize'),
                  fontWeight: FontWeight.w700,
                  color: ds.color('secondaryText'))),
          const SizedBox(height: 4),
          Text(remarks.isEmpty ? '無' : remarks,
              style: TextStyle(
                  fontSize: ds.metric('bodySize'),
                  fontStyle: remarks.isEmpty ? FontStyle.italic : null,
                  color: remarks.isEmpty
                      ? ds.color('secondaryText')
                      : ds.color('primaryText'))),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label,
      {required Color background, required Color foreground, IconData? icon}) {
    final ds = SystemTheme.of(context);
    final small = ds.metric('spaceSmall');
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: small * 1.25, vertical: small * .5),
      decoration: ShapeDecoration(
          color: background,
          shape: StadiumBorder(
              side: BorderSide(color: foreground.withOpacity(.35)))),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: ds.metric('labelSize') + 2, color: foreground),
          SizedBox(width: small * .5),
        ],
        Text(label,
            style: TextStyle(
                fontSize: ds.metric('labelSize'),
                fontWeight: FontWeight.w700,
                color: foreground)),
      ]),
    );
  }

  // 評級對應語意色 key，由 SystemTheme 依主題與明暗解析。
  String _ratingToneKey(PerformanceRating rating) => switch (rating) {
        PerformanceRating.excellent => 'success',
        PerformanceRating.good => 'info',
        PerformanceRating.average => 'warning',
        PerformanceRating.poor => 'error',
        _ => 'border',
      };
}
