import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/main/example/components/text_field/text_field_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'login_page_model.dart';
export 'login_page_model.dart';

class LoginPageWidget extends StatefulWidget {
  const LoginPageWidget({super.key});

  @override
  State<LoginPageWidget> createState() => LoginPageWidgetState();
}

class LoginPageWidgetState extends State<LoginPageWidget> {
  late LoginPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => LoginPageModel());

    logFirebaseEvent('screen_view', parameters: {'screen_name': 'queryPage'});
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
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        body: SafeArea(
          top: true,
          child: Container(
            width: 1512,
            height: 800,
            decoration: const BoxDecoration(
              image: DecorationImage(
                fit: BoxFit.contain,
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
                      color: Color(0xFFFFFFFF).withOpacity(0.8),
                      borderRadius: BorderRadius.circular(64),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical :86,horizontal :42),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text("黃絲帶愛網關懷協會"),
                          _textField("帳號", context),
                          _textField("密碼", context),
                          ElevatedButton(
                            onPressed: () {},
                            child: Text("登入"),
                          )
                        ],
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

  TextField _textField(String label, BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderSide: BorderSide(
            color: FlutterFlowTheme.of(context).tertiary,
          ),
        ),
        //   enabledBorder: OutlineInputBorder(
        //     borderSide: BorderSide(color: context.read<YrThemeCubit>().state.theme.color.text.defaulted),
        //   ),
        //   focusedBorder: OutlineInputBorder(
        //     borderSide: BorderSide(color: context.read<YrThemeCubit>().state.theme.color.text.defaulted),
        //   ),
        // ),
        // cursorColor: context.read<YrThemeCubit>().state.theme.color.text.defaulted,
      ),
    );
  }
}
