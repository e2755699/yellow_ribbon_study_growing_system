import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:ui_component/src/design_token.dart';
import 'package:ui_component/src/component/yr_form_warp.dart';
import 'package:ui_component/src/component/yr_text.dart';
import 'package:ui_component/ui_component.dart';

class YrSelector extends StatelessWidget {
  final String data;
  final List<String> items;
  final DsTheme theme;

  const YrSelector(this.data,
      {super.key, required this.items, this.theme = DsTheme.dark});

  @override
  Widget build(BuildContext context) {
    return YrFormWarp(
      child: Row(
        children: [
          YrText(data),
          Gap(context.read<YrThemeCubit>().state.theme.gap),
          DropdownMenu(
              dropdownMenuEntries: items.map((item) {
            return DropdownMenuEntry(value: items.indexOf(item), label: item);
          }).toList()),
        ],
      ),
    );
  }
}
