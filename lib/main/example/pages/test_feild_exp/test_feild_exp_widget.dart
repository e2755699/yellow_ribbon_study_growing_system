import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/main/components/yellow_ribbon_text_field/yellow_ribbon_text_field_widget.dart';
import '/main/example/components/text_field/text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'test_feild_exp_model.dart';
export 'test_feild_exp_model.dart';

class TestFeildExpWidget extends StatefulWidget {
  const TestFeildExpWidget({super.key});

  @override
  State<TestFeildExpWidget> createState() => _TestFeildExpWidgetState();
}

class _TestFeildExpWidgetState extends State<TestFeildExpWidget> {
  late TestFeildExpModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => TestFeildExpModel());

    logFirebaseEvent('screen_view',
        parameters: {'screen_name': 'test_feild_exp'});
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
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: () async {
              logFirebaseEvent('TEST_FEILD_EXP_arrow_back_rounded_ICN_ON');
              logFirebaseEvent('IconButton_navigate_back');
              context.pop();
            },
          ),
          title: Text(
            FFLocalizations.of(context).getText(
              'zr9j582k' /* Page Title */,
            ),
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: FlutterFlowTheme.of(context).headlineMediumFamily,
                  color: Colors.white,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  useGoogleFonts: GoogleFonts.asMap().containsKey(
                      FlutterFlowTheme.of(context).headlineMediumFamily),
                ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              wrapWithModel(
                model: _model.textFieldModel1,
                updateCallback: () => safeSetState(() {}),
                child: TextFieldWidget(
                  name: '姓名',
                  value: '劉兆凌',
                ),
              ),
              wrapWithModel(
                model: _model.textFieldModel2,
                updateCallback: () => safeSetState(() {}),
                child: TextFieldWidget(
                  name: '姓名',
                  value: '莊延安',
                ),
              ),
              wrapWithModel(
                model: _model.yellowRibbonTextFieldModel,
                updateCallback: () => safeSetState(() {}),
                child: YellowRibbonTextFieldWidget(
                  name: '姓名',
                  value: '劉兆凌',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
