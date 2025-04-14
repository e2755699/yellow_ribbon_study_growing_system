import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ui_component/src/design_token.dart';
import 'package:ui_component/ui_component.dart';

class YrText extends StatelessWidget {
  final String data;

  final Color? color;

  YrText(this.data, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      style:  TextStyle().copyWith(
        color: color ??
            context.read<YrThemeCubit>().state.theme.color.text.defaulted,
      ),
    );
  }
}
