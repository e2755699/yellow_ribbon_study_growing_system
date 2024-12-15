import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yb_layout.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_detail_page/student_detail_main_section.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_detail_page/student_detail_page_model.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

class StudentDetailPageWidget extends StatefulWidget {
  final StudentDetailCubit studentDetailCubit;

  const StudentDetailPageWidget({super.key, required this.studentDetailCubit});

  @override
  State<StudentDetailPageWidget> createState() =>
      StudentDetailPageWidgetState();
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
        child: BlocProvider.value(
          value: widget.studentDetailCubit,
          child: BlocBuilder<StudentDetailCubit, StudentDetailState>(
              builder: (context, state) {
            return StudentDetailMainSection(
              studentDetail: state.detail,
            );
          }),
        ));
  }
}

class LoginFormModel {
  final TextEditingController account;
  final TextEditingController pwd;
  final GlobalKey<FormState> formKey;

  factory LoginFormModel.create(GlobalKey<FormState> formState) {
    return LoginFormModel(formState,
        account: TextEditingController(), pwd: TextEditingController());
  }

  LoginFormModel(this.formKey, {required this.account, required this.pwd});

  bool get isValid => formKey.currentState?.validate() ?? false;
}
