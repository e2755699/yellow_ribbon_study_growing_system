import 'package:firebase_auth/firebase_auth.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:flutter/material.dart';
import 'login_page_model.dart';
export 'login_page_model.dart';
import 'package:fluttertoast/fluttertoast.dart';

class LoginPageWidget extends StatefulWidget {
  const LoginPageWidget({super.key});

  @override
  State<LoginPageWidget> createState() => LoginPageWidgetState();
}

class LoginPageWidgetState extends State<LoginPageWidget> {
  late LoginPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  late LoginFormModel _loginModel;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginPageModel());

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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Image(
                        image: AssetImage("assets/images/login_avatar.webp")),
                    flex: 4,
                  ),
                  Flexible(
                      flex: 6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: FlutterFlowTheme.of(context)
                              .tertiary
                              .withOpacity(0.8),
                          borderRadius: BorderRadius.circular(64),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 86, horizontal: 42),
                          child: Form(
                            key: formKey,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                Text(
                                  "黃絲帶愛網關懷協會",
                                  style: TextStyle(
                                    color: FlutterFlowTheme.of(context)
                                        .primaryText,
                                    fontSize: 24,
                                    fontFamily: 'Inter',
                                    fontWeight: FontWeight.w400,
                                    height: 0,
                                  ),
                                ),
                                _textField("帳號", context, _loginModel.account),
                                _textField("密碼", context, _loginModel.pwd, obscureText: true),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.all(
                                      FlutterFlowTheme.of(context).primary,
                                    )),
                                    onPressed: () async {
                                      if (_loginModel.isValid) {
                                        Fluttertoast.showToast(msg: "登入中");

                                        try {
                                          var userCredential =
                                              await FirebaseAuth.instance
                                                  .signInWithEmailAndPassword(
                                                      email: _loginModel
                                                          .account.text,
                                                      password:
                                                          _loginModel.pwd.text);
                                          Fluttertoast.showToast(
                                              msg:
                                                  "登入成功${userCredential.user?.email}");
                                          context.go(YbRoute.home.routeName);
                                        } catch (e) {
                                          Fluttertoast.showToast(
                                              msg: "登入失敗",
                                              toastLength: Toast.LENGTH_SHORT,
                                              gravity: ToastGravity.CENTER,
                                              timeInSecForIosWeb: 1,
                                              backgroundColor: Colors.red,
                                              textColor: FlutterFlowTheme.of(context).primaryBackground,
                                              fontSize: 16.0);
                                        }
                                      }
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: _text('登入',
                                          color: FlutterFlowTheme.of(context)
                                              .tertiary,
                                          size: 12),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            )),
          ),
        ),
      ),
    );
  }

  Text _text(String data, {Color? color, double? size}) {
    return Text(
      data,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _textField(
      String label, BuildContext context, TextEditingController controller,
      {bool obscureText = false}) {
    return TextFormField(
      obscureText: obscureText,
      controller: controller,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "請輸入$label";
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: FlutterFlowTheme.of(context).primary,
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: FlutterFlowTheme.of(context).primary,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            color: FlutterFlowTheme.of(context).primary,
          ),
        ),
        //   focusedBorder: OutlineInputBorder(
        //     borderSide: BorderSide(color: context.read<YrThemeCubit>().state.theme.color.text.defaulted),
        //   ),
        // ),
        // cursorColor: context.read<YrThemeCubit>().state.theme.color.text.defaulted,
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
