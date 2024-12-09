import '/flutter_flow/flutter_flow_util.dart';
import 'home_page_widget.dart' show HomePageWidget;
import 'package:flutter/material.dart';

class HomePageModel extends FlutterFlowModel<HomePageWidget> {
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

enum HomeButton {
  studentInfo("課輔資料","students"),
  dailyAttendance("每日出勤","everyday"),
  studentAssessment("成長評量","assessment"),
  growingReport("成長報告","school");

  final String name;
  final String iconName;

  const HomeButton(this.name, this.iconName);

}
