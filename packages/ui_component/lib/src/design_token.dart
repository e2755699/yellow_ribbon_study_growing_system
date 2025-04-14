import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:ui_component/src/design_system/ds_theme.dart';

enum DsTheme {
  light(false, color: DsColor.light),
  dark(true, color: DsColor.dark);

  final bool isDark;
  final DsColor color;
  final double space = 300;
  final double gap = 10;

  const DsTheme(
    this.isDark, {
    required this.color,
  });

  ThemeData getThemeData() {
    var themeData = isDark ? ThemeData.dark() : ThemeData.light();
    return themeData.copyWith(
      primaryColor: color.primaryColor,
      secondaryHeaderColor: color.secondaryColor,
    );
  }
}

enum DsButton {
  light(
      defaulted: DsColorToken.yellow10,
      disable: DsColorToken.yellow1,
      onPress: DsColorToken.yellow7),
  dark(
      defaulted: DsColorToken.yellow5,
      disable: DsColorToken.yellow1,
      onPress: DsColorToken.yellow7);

  const DsButton(
      {required this.defaulted, required this.disable, required this.onPress});

  final Color defaulted;
  final Color disable;
  final Color onPress;
}

enum DsColor {
  light(
    primaryColor: DsColorToken.yellow7,
    secondaryColor: DsColorToken.yellow9,
    backgroundColor: DsColorToken.yellow10,
    text: DsTextColor.light,
    button: DsButton.light,
  ),
  dark(
    primaryColor: DsColorToken.yellow1,
    secondaryColor: DsColorToken.yellow2,
    backgroundColor: DsColorToken.black7,
    text: DsTextColor.dark,
    button: DsButton.dark,
  );

  const DsColor({
    required this.text,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.button,
  });

  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final DsTextColor text;
  final DsButton button;
}

enum DsTextColor {
  light(
    defaulted: DsColorToken.yellow4,
    active: DsColorToken.yellow3,
  ),
  dark(
    defaulted: DsColorToken.yellow10,
    active: DsColorToken.yellow6,
  );

  final Color active;
  final Color defaulted;

  const DsTextColor({required this.active, required this.defaulted});
}

class DsColorToken {
  static const Color yellow1 = Color(0xFF292200);
  static const Color yellow2 = Color(0xFF443600);
  static const Color yellow3 = Color(0xFF5F4B00);
  static const Color yellow4 = Color(0xFF7A6600);
  static const Color yellow5 = Color(0xFF957F00);
  static const Color yellow6 = Color(0xFFB09800);
  static const Color yellow7 = Color(0xFFCCB100);
  static const Color yellow8 = Color(0xFFF5CC00);
  static const Color yellow9 = Color(0xFFFFE066);
  static const Color yellow10 = Color(0xFFFFF7EB);
  static const Color black1 = Color(0xFF000000);
  static const Color black2 = Color(0xD9000000);
  static const Color black3 = Color(0xB3000000);
  static const Color black4 = Color(0x8A000000);
  static const Color black5 = Color(0x73000000);
  static const Color black6 = Color(0x61000000);
  static const Color black7 = Color(0x4D000000);
  static const Color black8 = Color(0x33000000);
  static const Color black9 = Color(0x1A000000);
  static const Color black10 = Color(0x0D000000);
  static const Color white1 = Color(0xFFFFFFFF);
  static const Color white2 = Color(0xD9FFFFFF);
  static const Color white3 = Color(0xB3FFFFFF);
  static const Color white4 = Color(0x8AFFFFFF);
  static const Color white5 = Color(0x73FFFFFF);
  static const Color white6 = Color(0x61FFFFFF);
  static const Color white7 = Color(0x4DFFFFFF);
  static const Color white8 = Color(0x33FFFFFF);
  static const Color white9 = Color(0x1AFFFFFF);
  static const Color white10 = Color(0x0DFFFFFF);
}
