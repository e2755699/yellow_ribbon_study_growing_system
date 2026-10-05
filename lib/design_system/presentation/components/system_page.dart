import 'package:flutter/material.dart';
import '../../../main/components/yb_layout.dart';
import '../system_theme.dart';

/// Shared page chrome. YbLayout retains the application's save/back behavior.
class SystemPage extends StatelessWidget {
  const SystemPage(
      {super.key,
      required this.title,
      required this.scaffoldKey,
      required this.child,
      this.onBeforeExit,
      this.hasUnsavedChanges,
      this.isBusy,
      this.showSaveConfirmation = true,
      this.onBack});
  final String title;
  final GlobalKey<ScaffoldState> scaffoldKey;
  final Widget child;
  final Future<bool> Function()? onBeforeExit;
  final bool showSaveConfirmation;
  final bool Function()? hasUnsavedChanges;
  final bool Function()? isBusy;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    return YbLayout(
        title: title,
        scaffoldKey: scaffoldKey,
        headerColor: ds.color('secondaryBackground'),
        foregroundColor: ds.color('primaryText'),
        backgroundDecoration: BoxDecoration(color: ds.color('secondary')),
        onBeforeExit: onBeforeExit,
        hasUnsavedChanges: hasUnsavedChanges,
        isBusy: isBusy,
        onBack: onBack,
        showSaveConfirmation: showSaveConfirmation,
        child: child);
  }
}
