import 'package:flutter/material.dart';
import '../../../design_system/presentation/system_theme_scope.dart';
import '../../../domain/model/privacy_policy.dart';
import 'privacy_policy_view.dart';

/// App navigation adapter. Widgetbook renders PrivacyPolicyView directly.
Future<void> showPrivacyPolicy(BuildContext context) {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  return showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (dialogContext) => Dialog.fullscreen(
          child: SystemThemeScope(
              builder: (_) => PrivacyPolicyView(
                  scaffoldKey: scaffoldKey,
                  updated: privacyPolicyUpdated,
                  sections: privacyPolicySections,
                  onBack: () => Navigator.of(dialogContext).pop()))));
}
