import '/flutter_flow/flutter_flow_util.dart';
import 'text_field_widget.dart' show TextFieldWidget;
import 'package:flutter/material.dart';

class TextFieldModel extends FlutterFlowModel<TextFieldWidget> {
  ///  State fields for stateful widgets in this component.

  // State field(s) for TextField widget.
  FocusNode? textFieldFocusNode;
  TextEditingController? textController;
  String? Function(BuildContext, String?)? textControllerValidator;

  @override
  void initState(BuildContext context) {}

  @override
  void dispose() {
    textFieldFocusNode?.dispose();
    textController?.dispose();
  }
}
