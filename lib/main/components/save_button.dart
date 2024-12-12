import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';

class SaveButton extends StatelessWidget {
  const SaveButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
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
        onPressed: () {},
        child: Text("Save"));
  }
}
