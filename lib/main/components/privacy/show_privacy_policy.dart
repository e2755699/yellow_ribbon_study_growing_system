import 'package:flutter/material.dart';
import '../../../design_system/presentation/system_theme_scope.dart';
import '../../../domain/model/privacy_policy.dart';
import 'privacy_policy_view.dart';

/// App navigation adapter. Widgetbook renders PrivacyPolicyView directly.
///
/// 使用全螢幕 page route 而非 showDialog：showDialog 會在開啟當下複製呼叫端
/// 的 Theme，政策頁開著時切換明暗便不會更新。Page route 位於 App 根部 Theme
/// 之下，由自己的 SystemThemeScope 即時跟隨主題與明暗。
Future<void> showPrivacyPolicy(BuildContext context) {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  return Navigator.of(context).push<void>(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (routeContext) => SystemThemeScope(
          builder: (_) => PrivacyPolicyView(
              scaffoldKey: scaffoldKey,
              updated: privacyPolicyUpdated,
              sections: privacyPolicySections,
              onBack: () => Navigator.of(routeContext).pop()))));
}
