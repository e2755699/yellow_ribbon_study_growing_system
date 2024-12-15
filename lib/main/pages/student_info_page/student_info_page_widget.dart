import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_cubit/student_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/home_button.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yb_layout.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/daily_attendance_page/daily_attendance_page_widget.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/home_page/home_page_model.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_detail_page/student_detail_main_section.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';

class StudentInfoPageWidget extends StatefulWidget {
  const StudentInfoPageWidget({super.key});

  @override
  State<StudentInfoPageWidget> createState() => StudentInfoPageWidgetState();
}

class StudentInfoPageWidgetState extends State<StudentInfoPageWidget>
    with YbToolbox {
  late HomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final ValueNotifier<ClassLocation> _classLocationFilterNotifier =
      ValueNotifier(ClassLocation.values.first);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());

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
        title: HomeButton.studentInfo.name,
        child: Column(
          children: [
            tabSection(_classLocationFilterNotifier),
            Gap(FlutterFlowTheme.of(context).spaceLarge),
            Expanded(
              child: BlocBuilder<StudentsCubit,StudentsState>(
                bloc: StudentsCubit(StudentsState([]))..load(),
                builder: (context,state) {
                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisSpacing: FlutterFlowTheme.of(context).spaceMedium,
                      mainAxisSpacing: FlutterFlowTheme.of(context).spaceMedium,
                      crossAxisCount: 2,
                      childAspectRatio: 8 / 1,
                    ),
                    itemCount: state.students.length,
                    itemBuilder: (context, index) {
                      var student = state.students[index];
                      return Container(
                        padding: EdgeInsets.all(
                            FlutterFlowTheme.of(context).spaceMedium),
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context).primaryBackground,
                          border: Border.all(color: Colors.black, width: 1),
                          borderRadius: BorderRadius.all(Radius.circular(
                              FlutterFlowTheme.of(context).radiusSmall)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Icon(Icons.account_circle),
                            Gap(FlutterFlowTheme.of(context).spaceMedium),
                            Text(student.name),
                            Gap(FlutterFlowTheme.of(context).spaceMedium),
                            Text(student.email),
                            Gap(FlutterFlowTheme.of(context).spaceMedium),
                            Text(student.gender),
                            Spacer(),
                            TextButton.icon(
                                icon: Icon(
                                  Icons.delete_forever_sharp,
                                  color: FlutterFlowTheme.of(context).error,
                                ),
                                onPressed: () {},
                                label: Text(
                                  "刪除",
                                  style: TextStyle(
                                      color: FlutterFlowTheme.of(context).error),
                                )),
                            Gap(FlutterFlowTheme.of(context).spaceMedium),
                            TextButton.icon(
                                icon: Icon(Icons.edit,
                                    color: FlutterFlowTheme.of(context).primary),
                                onPressed: () {
                                  context.push("${YbRoute.studentDetail.routeName}/${Operate.edit.name}/${student.id}");
                                },
                                label: Text(
                                  "編輯",
                                  style: TextStyle(
                                      color: FlutterFlowTheme.of(context).primary),
                                ))
                          ],
                        ),
                      );
                    },
                  );
                }
              ),
            ),
          ],
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
