import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';

/// 搜尋欄。底色、邊框、圓角與文字色都交給 SystemTheme 的
/// inputDecorationTheme，與其他輸入欄位在 Light／Dark 一致。
class YbSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final double width;
  final double height;

  const YbSearchField({
    super.key,
    required this.controller,
    this.hintText = '搜尋...',
    this.onChanged,
    this.width = 220,
    this.height = 48,
  });

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    return SizedBox(
      width: width,
      height: height,
      child: TextFormField(
        controller: controller,
        onChanged: onChanged,
        textAlignVertical: TextAlignVertical.center,
        decoration: InputDecoration(
          hintText: hintText,
          isDense: true,
          contentPadding:
              EdgeInsets.symmetric(horizontal: ds.metric('spaceSmall')),
          prefixIcon:
              Icon(Icons.search, color: ds.color('secondaryText'), size: 20),
        ),
        style: TextStyle(
            fontSize: ds.metric('bodySize'), color: ds.color('primaryText')),
      ),
    );
  }
}
