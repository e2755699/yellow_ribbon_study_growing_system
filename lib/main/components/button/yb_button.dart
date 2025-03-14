import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';

class YbButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Icon icon;

  const YbButton(
      {super.key,
      required this.text,
      required this.onPressed,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
        icon: icon,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color?>(
            (Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) {
                return FlutterFlowTheme.of(context).primary.withOpacity(0.5);
              }
              return FlutterFlowTheme.of(context).primary;
            },
          ),
        ),
        onPressed: onPressed,
        label: Text(text));
  }
}
