import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/home_page/home_page_model.dart';
import 'package:yellow_ribbon_study_growing_system/model/enum/home_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  @override
  State<HomePageWidget> createState() => HomePageWidgetState();
}

class HomePageWidgetState extends State<HomePageWidget> {
  late HomePageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late LoginFormModel _loginModel;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HomePageModel());

    logFirebaseEvent('screen_view', parameters: {'screen_name': 'loginPage'});
    _model.nameTextController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();

    _model.bodTextController ??= TextEditingController();
    _model.bodFocusNode ??= FocusNode();
    _loginModel = LoginFormModel.create(formKey);
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.fitWidth,
                image: AssetImage("assets/images/login_bg.webp"),
              ),
            ),
            child: Center(
                child: SizedBox(
              width: 700,
              height: 500,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildButton(HomeButton.studentInfo),
                      Gap(16),
                      buildButton(HomeButton.dailyAttendance),
                    ],
                  ),
                  Gap(16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      buildButton(HomeButton.studentAssessment),
                      Gap(16),
                      buildButton(HomeButton.growingReport),
                    ],
                  ),
                ],
              ),
            )),
          ),
        ),
      ),
    );
  }

  Widget buildButton(HomeButton homeButton) => ElevatedButton(
      style: ButtonStyle(
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(64), // 設置圓角半徑為 64
          )),
          backgroundColor: WidgetStateProperty.all(
            FlutterFlowTheme.of(context).primary,
          )),
      onPressed: () {
        context.push(homeButton.routeName);
      },
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(width: 140, "assets/images/${homeButton.iconName}.svg"),
            _text(homeButton.name),
          ],
        ),
      ));

  Text _text(String data, {Color? color, double? size}) {
    return Text(
      data,
      style: TextStyle(
        color: color,
        fontSize: 32,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
      ),
    );
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
