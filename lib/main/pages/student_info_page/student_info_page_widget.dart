import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_cubit/student_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/home_button.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/mixin/yb_toobox.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/button/create_button.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/button/yb_button.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/student_info/student_info_card.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/yb_layout.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/home_page/home_page_model.dart';
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
            tabSection(_classLocationFilterNotifier, operators: () {
              return [
                CreateButton(onPressed: () {
                  context.push(
                      "${YbRoute.studentDetail.routeName}/${Operate.create.name}/null");
                }),
              ];
            }),
            Gap(FlutterFlowTheme.of(context).spaceLarge),
            Expanded(
              child: BlocProvider(
                create: (context) => StudentsCubit(StudentsState([]))..load(),
                child: BlocBuilder<StudentsCubit, StudentsState>(
                    builder: (context, state) {
                  return ValueListenableBuilder(
                      valueListenable: _classLocationFilterNotifier,
                      builder: (context, filter, _) {
                        var students = state.students
                            .where((student) =>
                                student.classLocation == filter.name)
                            .toList();
                        return GridView.builder(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisSpacing:
                                FlutterFlowTheme.of(context).spaceMedium,
                            mainAxisSpacing:
                                FlutterFlowTheme.of(context).spaceMedium,
                            crossAxisCount: 2,
                            childAspectRatio: 8 / 1,
                          ),
                          itemCount: students.length,
                          itemBuilder: (context, index) {
                            var student = students[index];
                            return StudentInfoCard(student: student);
                          },
                        );
                      });
                }),
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
