import 'package:flutter/material.dart';
import '../../../design_system/presentation/system_theme.dart';

/// Shared visual only; authentication and navigation belong to the page adapter.
class SignOutButton extends StatelessWidget {
  const SignOutButton({super.key, required this.onPressed, this.busy = false});

  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    return Material(
      color: ds.color('secondaryBackground'),
      borderRadius: ds.cardRadius,
      child: TextButton.icon(
        onPressed: busy ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: ds.color('primaryText'),
          disabledForegroundColor: ds.color('secondaryText').withOpacity(.5),
          minimumSize: const Size(44, 44),
          padding: EdgeInsets.symmetric(horizontal: ds.metric('spaceMedium')),
          textStyle: TextStyle(fontSize: ds.metric('labelSize')),
          shape: RoundedRectangleBorder(borderRadius: ds.cardRadius),
        ),
        icon: busy
            ? SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: ds.color('secondaryText')))
            : const Icon(Icons.logout, size: 20),
        label: Text(busy ? '登出中…' : '登出'),
      ),
    );
  }
}
