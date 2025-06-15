import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_state.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yb_layout.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_detail_page/student_detail_main_section.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_detail_page/student_detail_page_model.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

class StudentDetailPageWidget extends StatefulWidget {
  const StudentDetailPageWidget({super.key});

  @override
  State<StudentDetailPageWidget> createState() =>
      StudentDetailPageWidgetState();

  factory StudentDetailPageWidget.fromRouteParams(Operate operate, String sid) {
    return const StudentDetailPageWidget();
  }
}

class StudentDetailPageWidgetState extends State<StudentDetailPageWidget> {
  late StudentDetaiPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => StudentDetaiPageModel());

    logFirebaseEvent('screen_view',
        parameters: {'screen_name': 'studentInfoPage'});
    _model.nameTextController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();

    _model.bodTextController ??= TextEditingController();
    _model.bodFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YbLayout(
        scaffoldKey: scaffoldKey,
        title: "學生資料",
        onBeforeExit: () async {
          final cubit = context.read<StudentDetailCubit>();
          return !cubit.hasUnsavedChanges();
        },
        showSaveConfirmation: context.read<StudentDetailCubit>().hasUnsavedChanges(),
        child: BlocBuilder<StudentDetailCubit, StudentDetailState>(
            builder: (context, state) {
          if (state is StudentDetailLoaded) {
            return StudentDetailMainSection(
              studentDetail: state.detail,
            );
          } else if (state is StudentDetailError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(state.message, style: TextStyle(fontSize: 16)),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("返回"),
                  ),
                ],
              ),
            );
          } else {
            // StudentDetailInitial 或載入中狀態
            return const Center(child: CircularProgressIndicator());
          }
        }));
  }
}

