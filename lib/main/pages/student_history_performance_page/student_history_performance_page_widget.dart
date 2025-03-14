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
import 'package:yellow_ribbon_study_growing_system/main/components/student_info/info_card_layout.dart';
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
  factory StudentHistoryPerformancePageWidget.fromParams(Map<String, String> pathParameters) {
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

  @override
  void initState() {
    super.initState();
    _model = widget.studentPerformanceCubit;
    
    // 加载学生表现记录
    if (widget.studentId.isNotEmpty) {
      _model.load(widget.studentId);
    }
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

            // 使用StudentPerformanceMainSection显示所有记录
            // 不进行日期过滤，显示所有历史记录
            return StudentHistoryPerformanceMainSection(
              studentId: state.studentId,
              records: state.records,
              studentDetail: state.studentDetail,
            );
          },
        ),
      ),
    );
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
    final studentName = studentDetail?.name ?? 
                        (records.isNotEmpty ? records[0].name : '');

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 只显示表现记录卡片
            InfoCardLayoutWith1Column(
              title: '表現記錄 - $studentName',
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
            // 表现详情
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 左侧：上课表现和作业完成情况
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 上课表现评分
                      Row(
                        children: [
                          const Text('上課表現：'),
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
                      const Gap(8),
                      
                      // 是否完成作业
                      Row(
                        children: [
                          const Text('完成作業：'),
                          const Gap(8),
                          ValueListenableBuilder(
                            valueListenable: record.homeworkCompletedNotifier,
                            builder: (context, homeworkCompleted, _) => Text(
                              homeworkCompleted ? '是' : '否',
                              style: TextStyle(
                                color: homeworkCompleted ? Colors.green : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // 右侧：小帮手和备注
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 是否小帮手
                      Row(
                        children: [
                          const Text('小幫手：'),
                          const Gap(8),
                          ValueListenableBuilder(
                            valueListenable: record.isHelperNotifier,
                            builder: (context, isHelper, _) => Text(
                              isHelper ? '是' : '否',
                              style: TextStyle(
                                color: isHelper ? Colors.blue : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      
                      // 备注
                      Row(
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
                                  fontStyle: remarks.isEmpty ? FontStyle.italic : FontStyle.normal,
                                  color: remarks.isEmpty ? Colors.grey : Colors.black,
                                ),
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