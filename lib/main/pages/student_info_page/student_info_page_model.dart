import '/flutter_flow/flutter_flow_util.dart';
import 'student_info_page_widget.dart' show StudentInfoPageWidget;
import 'package:flutter/material.dart';

class StudentInfoPageModel extends FlutterFlowModel<StudentInfoPageWidget> {
  ///  Local state fields for this page.

  String pageTitle = '登入頁面';

  ///  State fields for stateful widgets in this page.

  final formKey = GlobalKey<FormState>();

  // State field(s) for name widget.
  FocusNode? nameFocusNode;
  TextEditingController? nameTextController;
  String? Function(BuildContext, String?)? nameTextControllerValidator;

  String? _nameTextControllerValidator(BuildContext context, String? val) {
    if (val == null || val.isEmpty) {
      return FFLocalizations.of(context).getText(
        '8ys5sqnb' /* Field is required */,
      );
    }

    return null;
  }

  // State field(s) for bod widget.
  FocusNode? bodFocusNode;
  TextEditingController? bodTextController;
  String? Function(BuildContext, String?)? bodTextControllerValidator;

  @override
  void initState(BuildContext context) {
    nameTextControllerValidator = _nameTextControllerValidator;
  }

  @override
  void dispose() {
    nameFocusNode?.dispose();
    nameTextController?.dispose();

    bodFocusNode?.dispose();
    bodTextController?.dispose();
  }
}
