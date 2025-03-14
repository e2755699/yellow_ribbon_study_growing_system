import 'package:collection/collection.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_daily_performance_cubit/daily_performance_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/home_button.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/performance_rating.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/daily_performance/student_daily_performance_info.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_performance_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/button/yb_button.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/search_field/index.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yb_layout.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/home_page/home_page_model.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_performance_cubit/student_performance_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_performance_page/student_performance_main_section.dart';

class StudentPerformancePageWidget extends StatefulWidget {
  final StudentPerformanceCubit studentPerformanceCubit;
  final String? studentId;

  const StudentPerformancePageWidget({
    super.key, 
    required this.studentPerformanceCubit,
    this.studentId,
  });

  @override
  State<StudentPerformancePageWidget> createState() =>
      StudentPerformancePageWidgetState();

  factory StudentPerformancePageWidget.fromRouteParams(String sid) {
    final studentsRepo = StudentsRepo();
   final dailyPerformanceRepo = DailyPerformanceRepo(studentsRepo);

    final studentPerformanceCubit = StudentPerformanceCubit(
        StudentPerformanceState(sid, [], Operate.view),dailyPerformanceRepo);
    return StudentPerformancePageWidget(
      studentPerformanceCubit: studentPerformanceCubit,
      studentId: sid,
    );
  }
  
  factory StudentPerformancePageWidget.create({String? studentId}) {
    final studentsRepo = StudentsRepo();
    final dailyPerformanceRepo = DailyPerformanceRepo(studentsRepo);
    final studentPerformanceCubit = StudentPerformanceCubit(
        StudentPerformanceState(studentId ?? '', [], Operate.view),dailyPerformanceRepo);
    return StudentPerformancePageWidget(
      studentPerformanceCubit: studentPerformanceCubit,
      studentId: studentId,
    );
  }
}

class StudentPerformancePageWidgetState extends State<StudentPerformancePageWidget>
    with YbToolbox {
  late HomePageModel _model;
  late StudentPerformanceCubit _studentPerformanceCubit;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final DateTime date = DateTime.now();
  final ValueNotifier<ClassLocation> _classLocationFilterNotifier =
      ValueNotifier(ClassLocation.values.first);
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchTextNotifier = ValueNotifier('');

  @override
  void initState() {
    super.initState();
    _studentPerformanceCubit = widget.studentPerformanceCubit;
    
    _model = createModel(context, () => HomePageModel());
    logFirebaseEvent('screen_view',
        parameters: {'screen_name': 'studentPerformancePage'});
    _model.nameTextController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();

    _model.bodTextController ??= TextEditingController();
    _model.bodFocusNode ??= FocusNode();
    _classLocationFilterNotifier.addListener(() {
      if (widget.studentId != null && widget.studentId!.isNotEmpty) {
        _studentPerformanceCubit.load(widget.studentId!);
      }
    });
    
    _searchController.addListener(() {
      _searchTextNotifier.value = _searchController.text;
    });
    
    // 加载学生表现数据
    if (widget.studentId != null && widget.studentId!.isNotEmpty) {
      _studentPerformanceCubit.load(widget.studentId!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _model.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YbLayout(
        scaffoldKey: scaffoldKey,
        title: "學生表現",
        child: BlocProvider.value(
          value: _studentPerformanceCubit,
          child: BlocBuilder<StudentPerformanceCubit, StudentPerformanceState>(
              builder: (context, state) {
            return Column(
              children: [
                // 操作按钮区域
                _buildActionButtons(context, state),
                
                // 主内容区域
                Expanded(
                  child: StudentPerformanceMainSection(
                    studentId: state.studentId,
                    records: state.records,
                    isEditing: state.operate == Operate.edit,
                    studentDetail: state.studentDetail,
                    onRecordChanged: (record) {
                      if (state.operate == Operate.edit) {
                        _studentPerformanceCubit.updateRecord(record);
                      }
                    },
                  ),
                ),
              ],
            );
          }),
        ));
  }
  
  Widget _buildActionButtons(BuildContext context, StudentPerformanceState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (state.operate == Operate.view) ...[
            YbButton(
              text: '編輯',
              onPressed: () {
                _studentPerformanceCubit.edit();
              },
              icon: const Icon(Icons.edit, size: 20),
            ),
          ] else if (state.operate == Operate.edit) ...[
            YbButton(
              text: '儲存',
              onPressed: () {
                _studentPerformanceCubit.save();
              },
              icon: const Icon(Icons.save, size: 20),
            ),
            const SizedBox(width: 16),
            YbButton(
              text: '取消',
              onPressed: () {
                _studentPerformanceCubit.cancelEdit();
              },
              icon: const Icon(Icons.cancel, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}

class _PerformanceListItem extends StatelessWidget {
  final StudentDailyPerformanceRecord student;

  const _PerformanceListItem(this.student);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 学生姓名和基本信息
            Row(
              children: [
                Expanded(
                  child: Text(
                    student.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                Text('據點: ${student.classLocation.name}'),
              ],
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
                              valueListenable: student.performanceRatingNotifier,
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
                            valueListenable: student.homeworkCompletedNotifier,
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
                            valueListenable: student.isHelperNotifier,
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
                              valueListenable: student.remarksNotifier,
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