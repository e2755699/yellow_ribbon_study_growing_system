import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_component/src/component/yr_text.dart';
import 'package:ui_component/ui_component.dart';

class YrButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget? child;
  final String? text;

  const YrButton({super.key, required this.onPressed, this.child, this.text});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        onPressed();
      },
      style: ButtonStyle(
        backgroundColor:
            WidgetStateProperty.resolveWith<Color?>((Set<WidgetState> states) {
          if (states.contains(WidgetState.pressed)) {
            return context
                .read<YrThemeCubit>()
                .state
                .theme
                .color
                .button
                .onPress;
          } else if (states.contains(WidgetState.disabled)) {
            return context
                .read<YrThemeCubit>()
                .state
                .theme
                .color
                .button
                .disable;
          }
          return context
              .read<YrThemeCubit>()
              .state
              .theme
              .color
              .button
              .defaulted;
        }),
      ),
      child: child ?? YrText(text ?? ""),
    );
  }
}
