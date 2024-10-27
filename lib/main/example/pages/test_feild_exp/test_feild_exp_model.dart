import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/main/components/yellow_ribbon_text_field/yellow_ribbon_text_field_widget.dart';
import '/main/example/components/text_field/text_field_widget.dart';
import 'test_feild_exp_widget.dart' show TestFeildExpWidget;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class TestFeildExpModel extends FlutterFlowModel<TestFeildExpWidget> {
  ///  State fields for stateful widgets in this page.

  // Model for text_field component.
  late TextFieldModel textFieldModel1;
  // Model for text_field component.
  late TextFieldModel textFieldModel2;
  // Model for YellowRibbonTextField component.
  late YellowRibbonTextFieldModel yellowRibbonTextFieldModel;

  @override
  void initState(BuildContext context) {
    textFieldModel1 = createModel(context, () => TextFieldModel());
    textFieldModel2 = createModel(context, () => TextFieldModel());
    yellowRibbonTextFieldModel =
        createModel(context, () => YellowRibbonTextFieldModel());
  }

  @override
  void dispose() {
    textFieldModel1.dispose();
    textFieldModel2.dispose();
    yellowRibbonTextFieldModel.dispose();
  }
}
