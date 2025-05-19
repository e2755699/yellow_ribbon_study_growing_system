import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_performance_cubit/student_performance_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/performance_rating.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_performance/student_daily_performance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_performance_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/utils/date_formatter.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_util.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/nav/nav.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/rating_scale/five_point_rating_scale.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/student_info/info_card_layout.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yb_dropdown_menu/month_filter_dropdown_menu.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yb_layout.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_performance_page/student_performance_main_section.dart';

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
    print('月份筛选变化: ${_monthFilterNotifier.value}');
    // 强制重新构建页面
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    return BlocProvider(
      create: (context) => _model,
      child: YbLayout(
        scaffoldKey: scaffoldKey,
        title: '學生歷史表現記錄',
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

            // 构建筛选器
            final filterWidget =
                _buildFilterWidget(dateRange.earliest, dateRange.latest);

            // 筛选记录
            final filteredRecords = _filterRecordsByMonth(state.records);

            // 使用StudentPerformanceMainSection显示所有记录
            return Column(
              children: [
                // 筛选器
                filterWidget,
                const SizedBox(height: 16),
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

  // 构建筛选器
  Widget _buildFilterWidget(DateTime earliest, DateTime latest) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          MonthFilterDropdownMenu(
            monthFilterNotifier: _monthFilterNotifier,
            earliestDate: earliest,
            latestDate: latest,
            labelPrefix: '月份',
          ),
          const Spacer(),
          Text(
            '共 ${_filterRecordsByMonth(_model.state.records).length} 筆記錄',
            style: FlutterFlowTheme.of(context).bodyMedium,
          ),
        ],
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
    print('筛选月份: $selectedMonth, 记录数: ${records.length}');

    if (selectedMonth == null) {
      // 不筛选，返回所有记录（按日期从新到旧排序）
      final sortedRecords = _sortRecordsByDate(records);
      print('全部记录数: ${sortedRecords.length}');
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
    print('筛选后记录数: ${sortedRecords.length}');
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
    print('构建StudentHistoryPerformanceMainSection，记录数: ${records.length}');

    if (records.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: FlutterFlowTheme.of(context).secondaryText,
            ),
            const Gap(16),
            Text(
              '找不到該學生的表現記錄',
              style: FlutterFlowTheme.of(context).titleMedium,
            ),
          ],
        ),
      );
    }

    // 获取学生姓名（从第一条记录中获取）
    final studentName =
        studentDetail?.name ?? (records.isNotEmpty ? records[0].name : '');

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 只显示表现记录卡片
            InfoCardLayoutWith1Column(
              title: '表現記錄 - $studentName (${records.length}筆)',
              columns1: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: records.map((record) {
                      return _buildPerformanceCard(context, record);
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(
      BuildContext context, StudentDailyPerformanceRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期
            Text(
              '日期：${DateFormatter.formatToYYYYMMDD(record.recordDate)}',
              style: FlutterFlowTheme.of(context).titleSmall,
            ),
            const Divider(),

            // 主要表現評分部分
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 上課表現評級（原有的）
                Row(
                  children: [
                    const Text('上課表現評級：'),
                    const Gap(8),
                    Expanded(
                      child: ValueListenableBuilder(
                        valueListenable: record.performanceRatingNotifier,
                        builder: (context, performanceRating, _) => Text(
                          performanceRating.label,
                          style: TextStyle(
                            color: _getPerformanceColor(performanceRating),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(16),

                // 五度量表評分區域
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    '課程表現評分：',
                    style: FlutterFlowTheme.of(context).labelLarge,
                  ),
                ),

                // 五度量表評分 - 上課表現
                FivePointRatingScale(
                  value: record.classPerformanceRatingNotifier.value,
                  isEditable: false,
                  title: '上課表現',
                ),
                const Gap(8),

                // 五度量表評分 - 數學成績
                FivePointRatingScale(
                  value: record.mathPerformanceRatingNotifier.value,
                  isEditable: false,
                  title: '數學成績',
                ),
                const Gap(8),

                // 五度量表評分 - 國文成績
                FivePointRatingScale(
                  value: record.chinesePerformanceRatingNotifier.value,
                  isEditable: false,
                  title: '國文成績',
                ),
                const Gap(8),

                // 五度量表評分 - 英文成績
                FivePointRatingScale(
                  value: record.englishPerformanceRatingNotifier.value,
                  isEditable: false,
                  title: '英文成績',
                ),
                const Gap(8),

                // 五度量表評分 - 社會成績
                FivePointRatingScale(
                  value: record.socialPerformanceRatingNotifier.value,
                  isEditable: false,
                  title: '社會成績',
                ),
                const Gap(16),

                // 其他信息區域
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 左侧：完成作业
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 是否完成作业
                          Row(
                            children: [
                              const Text('完成作業：'),
                              const SizedBox(width: 8),
                              ValueListenableBuilder(
                                valueListenable: record.excellentCharactersNotifier,
                                builder: (context, excellentCharacters, _) => Text(
                                  record.homeworkCompleted ? '是' : '否',
                                  style: TextStyle(
                                    color: record.homeworkCompleted ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          
                          // 是否小帮手
                          Row(
                            children: [
                              const Text('小幫手：'),
                              const SizedBox(width: 8),
                              ValueListenableBuilder(
                                valueListenable: record.excellentCharactersNotifier,
                                builder: (context, excellentCharacters, _) => Text(
                                  record.isHelper ? '是' : '否',
                                  style: TextStyle(
                                    color: record.isHelper ? Colors.blue : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // 表現描述（放在最下面）
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('表現描述：'),
                      const Gap(8),
                      Expanded(
                        child: ValueListenableBuilder(
                          valueListenable: record.remarksNotifier,
                          builder: (context, remarks, _) => Text(
                            remarks.isEmpty ? '無' : remarks,
                            style: TextStyle(
                              fontStyle: remarks.isEmpty
                                  ? FontStyle.italic
                                  : FontStyle.normal,
                              color:
                                  remarks.isEmpty ? Colors.grey : Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getPerformanceColor(PerformanceRating rating) {
    switch (rating) {
      case PerformanceRating.excellent:
        return Colors.green;
      case PerformanceRating.good:
        return Colors.blue;
      case PerformanceRating.average:
        return Colors.orange;
      case PerformanceRating.poor:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
