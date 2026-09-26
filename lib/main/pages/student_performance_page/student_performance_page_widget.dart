import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_performance_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/components/system_page.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/home_page/home_page_model.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/components/system_page_header.dart';
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
        StudentPerformanceState(sid, [], Operate.view), dailyPerformanceRepo);
    return StudentPerformancePageWidget(
      studentPerformanceCubit: studentPerformanceCubit,
      studentId: sid,
    );
  }

  factory StudentPerformancePageWidget.create({String? studentId}) {
    final studentsRepo = StudentsRepo();
    final dailyPerformanceRepo = DailyPerformanceRepo(studentsRepo);
    final studentPerformanceCubit = StudentPerformanceCubit(
        StudentPerformanceState(studentId ?? '', [], Operate.view),
        dailyPerformanceRepo);
    return StudentPerformancePageWidget(
      studentPerformanceCubit: studentPerformanceCubit,
      studentId: studentId,
    );
  }
}

class StudentPerformancePageWidgetState
    extends State<StudentPerformancePageWidget> with YbToolbox {
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
    // Provider 必須在 YbLayout 之上：返回保存判斷會讀取本頁 Cubit。
    return BlocProvider.value(
      value: _studentPerformanceCubit,
      child: BlocBuilder<StudentPerformanceCubit, StudentPerformanceState>(
          builder: (context, state) {
        return SystemPage(
            scaffoldKey: scaffoldKey,
            title: "學生表現",
            onBeforeExit: _studentPerformanceCubit.saveBeforeExit,
            showSaveConfirmation: _studentPerformanceCubit.hasUnsavedChanges(),
            child: Column(
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
            ));
      }),
    );
  }

  Widget _buildActionButtons(
      BuildContext context, StudentPerformanceState state) {
    // 與其他頁一致：共用頁首，主操作放右上。
    final name = state.studentDetail?.name ??
        (state.records.isNotEmpty ? state.records.first.name : '學生');
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SystemPageHeader(
        title: name,
        subtitle: state.operate == Operate.edit ? '編輯中，完成後請按儲存。' : '近一個月的表現紀錄。',
        action: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 與學生詳情一致：檢視時「編輯」為次要外框按鈕，編輯時「儲存」為主按鈕。
            if (state.operate == Operate.view) ...[
              OutlinedButton.icon(
                onPressed: _studentPerformanceCubit.edit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('編輯'),
              ),
            ] else if (state.operate == Operate.edit) ...[
              OutlinedButton.icon(
                onPressed: _studentPerformanceCubit.cancelEdit,
                icon: const Icon(Icons.close_rounded),
                label: const Text('取消'),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _studentPerformanceCubit.save,
                icon: const Icon(Icons.save),
                label: const Text('儲存'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
