import 'package:flutter/material.dart';
import '../../../design_system/presentation/system_theme.dart';

/// The production login action; authentication stays in the page adapter.
class LoginSubmitButton extends StatelessWidget {
  const LoginSubmitButton({
    super.key,
    required this.onPressed,
    this.submitting = false,
  });

  final VoidCallback? onPressed;
  final bool submitting;

  @override
  Widget build(BuildContext context) {
    final theme = SystemTheme.of(context);
    final disabledForeground = theme.color('secondaryText');
    return ElevatedButton(
      style: theme.materialTheme().elevatedButtonTheme.style!.copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.disabled)
                    ? theme.color('border').withOpacity(.35)
                    : theme.backgroundFor(states)),
            foregroundColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.disabled)
                    ? disabledForeground
                    : theme.onPrimary),
          ),
      onPressed: submitting ? null : onPressed,
      child: submitting
          ? Semantics(
              liveRegion: true,
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: theme.metric('spaceSmall'),
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: disabledForeground, strokeWidth: 2),
                  ),
                  const Text('登入中…'),
                ],
              ),
            )
          : const Text('登入'),
    );
  }
}
