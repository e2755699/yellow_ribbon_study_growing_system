// ignore_for_file: overridden_fields, annotate_overrides

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shared_preferences/shared_preferences.dart';

const kThemeModeKey = '__theme_mode__';
SharedPreferences? _prefs;

enum DeviceSize {
  mobile,
  tablet,
  desktop,
}

abstract class FlutterFlowTheme {
  static DeviceSize deviceSize = DeviceSize.mobile;

  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();

  static ThemeMode get themeMode {
    final darkMode = _prefs?.getBool(kThemeModeKey);
    return darkMode == null
        ? ThemeMode.system
        : darkMode
            ? ThemeMode.dark
            : ThemeMode.light;
  }

  static void saveThemeMode(ThemeMode mode) => mode == ThemeMode.system
      ? _prefs?.remove(kThemeModeKey)
      : _prefs?.setBool(kThemeModeKey, mode == ThemeMode.dark);

  static FlutterFlowTheme of(BuildContext context) {
    deviceSize = getDeviceSize(context);
    return Theme.of(context).brightness == Brightness.dark
        ? DarkModeTheme()
        : LightModeTheme();
  }

  @Deprecated('Use primary instead')
  Color get primaryColor => primary;

  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;

  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  late Color primary;
  late Color secondary;
  late Color tertiary;
  late Color alternate;
  late Color primaryText;
  late Color secondaryText;
  late Color primaryBackground;
  late Color secondaryBackground;
  late Color onPrimary;
  late Color accent1;
  late Color accent2;
  late Color accent3;
  late Color accent4;
  late Color success;
  late Color warning;
  late Color error;
  late Color info;
  late Color borderPrimary;
  late double spaceMedium;
  late double spaceLarge;
  late double spaceXLarge;
  late double spaceXXLarge;

  late double radiusSmall;
  late double radiusMedium;

  late double textHeadlineSize;
  late double textTitleSize;
  late double textBody1Size;
  late double textBody2Size;
  late double textButtonSize;

  @Deprecated('Use displaySmallFamily instead')
  String get title1Family => displaySmallFamily;

  @Deprecated('Use displaySmall instead')
  TextStyle get title1 => typography.displaySmall;

  @Deprecated('Use headlineMediumFamily instead')
  String get title2Family => typography.headlineMediumFamily;

  @Deprecated('Use headlineMedium instead')
  TextStyle get title2 => typography.headlineMedium;

  @Deprecated('Use headlineSmallFamily instead')
  String get title3Family => typography.headlineSmallFamily;

  @Deprecated('Use headlineSmall instead')
  TextStyle get title3 => typography.headlineSmall;

  @Deprecated('Use titleMediumFamily instead')
  String get subtitle1Family => typography.titleMediumFamily;

  @Deprecated('Use titleMedium instead')
  TextStyle get subtitle1 => typography.titleMedium;

  @Deprecated('Use titleSmallFamily instead')
  String get subtitle2Family => typography.titleSmallFamily;

  @Deprecated('Use titleSmall instead')
  TextStyle get subtitle2 => typography.titleSmall;

  @Deprecated('Use bodyMediumFamily instead')
  String get bodyText1Family => typography.bodyMediumFamily;

  @Deprecated('Use bodyMedium instead')
  TextStyle get bodyText1 => typography.bodyMedium;

  @Deprecated('Use bodySmallFamily instead')
  String get bodyText2Family => typography.bodySmallFamily;

  @Deprecated('Use bodySmall instead')
  TextStyle get bodyText2 => typography.bodySmall;

  String get displayLargeFamily => typography.displayLargeFamily;

  TextStyle get displayLarge => typography.displayLarge;

  String get displayMediumFamily => typography.displayMediumFamily;

  TextStyle get displayMedium => typography.displayMedium;

  String get displaySmallFamily => typography.displaySmallFamily;

  TextStyle get displaySmall => typography.displaySmall;

  String get headlineLargeFamily => typography.headlineLargeFamily;

  TextStyle get headlineLarge => typography.headlineLarge;

  String get headlineMediumFamily => typography.headlineMediumFamily;

  TextStyle get headlineMedium => typography.headlineMedium;

  String get headlineSmallFamily => typography.headlineSmallFamily;

  TextStyle get headlineSmall => typography.headlineSmall;

  String get titleLargeFamily => typography.titleLargeFamily;

  TextStyle get titleLarge => typography.titleLarge;

  String get titleMediumFamily => typography.titleMediumFamily;

  TextStyle get titleMedium => typography.titleMedium;

  String get titleSmallFamily => typography.titleSmallFamily;

  TextStyle get titleSmall => typography.titleSmall;

  String get labelLargeFamily => typography.labelLargeFamily;

  TextStyle get labelLarge => typography.labelLarge;

  String get labelMediumFamily => typography.labelMediumFamily;

  TextStyle get labelMedium => typography.labelMedium;

  String get labelSmallFamily => typography.labelSmallFamily;

  TextStyle get labelSmall => typography.labelSmall;

  String get bodyLargeFamily => typography.bodyLargeFamily;

  TextStyle get bodyLarge => typography.bodyLarge;

  String get bodyMediumFamily => typography.bodyMediumFamily;

  TextStyle get bodyMedium => typography.bodyMedium;

  String get bodySmallFamily => typography.bodySmallFamily;

  TextStyle get bodySmall => typography.bodySmall;

  Typography get typography => {
        DeviceSize.mobile: MobileTypography(this),
        DeviceSize.tablet: TabletTypography(this),
        DeviceSize.desktop: DesktopTypography(this),
      }[deviceSize]!;
}

DeviceSize getDeviceSize(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 479) {
    return DeviceSize.mobile;
  } else if (width < 991) {
    return DeviceSize.tablet;
  } else {
    return DeviceSize.desktop;
  }
}

class LightModeTheme extends FlutterFlowTheme {
  @Deprecated('Use primary instead')
  Color get primaryColor => primary;

  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;

  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  late Color secondaryBackground = const Color(0xFFEEBF2B);
  late Color primaryBackground = const Color(0xFFFDF2CB);
  late Color onPrimary = const Color(0xFFFFFFFF);
  late Color secondary = const Color(0xFFFFFDF1);
  late Color primary = const Color(0xFF7088D7);
  late Color primaryText = const Color(0xFF333333);
  late Color accent1 = const Color(0xFFEEBF2B);
  late Color error = const Color(0xFFFF5963);
  late Color success = const Color(0xFF1BB100);
  late Color outline = const Color(0xFFB6B6B6);
  late Color tertiary = const Color(0xFFFFFFFF);
  late Color borderPrimary = const Color(0x00000000);

  //-----------以上有符合設計guideline-----------
  late Color alternate = const Color(0xFFE0E3E7);

  //Neutral/800
  late Color secondaryText = const Color(0xFF7F7F7F);
  late Color accent2 = const Color(0x4D39D2C0);
  late Color accent3 = const Color(0x4DEE8B60);
  late Color accent4 = const Color(0xCCFFFFFF);
  late Color warning = const Color(0xFFF9CF58);
  late Color info = const Color(0xFFFFFFFF);
  late double spaceMedium = 16;
  late double spaceLarge = 32;
  late double spaceXLarge = 64;
  late double spaceXXLarge = 128;
  late double radiusSmall = 16;
  late double radiusMedium = 32;

  late double textHeadlineSize = 60;
  late double textTitleSize = 40;
  late double textBody1Size = 24;
  late double textBody2Size = 20;
  late double textButtonSize = 24;
}

abstract class Typography {
  String get displayLargeFamily;

  TextStyle get displayLarge;

  String get displayMediumFamily;

  TextStyle get displayMedium;

  String get displaySmallFamily;

  TextStyle get displaySmall;

  String get headlineLargeFamily;

  TextStyle get headlineLarge;

  String get headlineMediumFamily;

  TextStyle get headlineMedium;

  String get headlineSmallFamily;

  TextStyle get headlineSmall;

  String get titleLargeFamily;

  TextStyle get titleLarge;

  String get titleMediumFamily;

  TextStyle get titleMedium;

  String get titleSmallFamily;

  TextStyle get titleSmall;

  String get labelLargeFamily;

  TextStyle get labelLarge;

  String get labelMediumFamily;

  TextStyle get labelMedium;

  String get labelSmallFamily;

  TextStyle get labelSmall;

  String get bodyLargeFamily;

  TextStyle get bodyLarge;

  String get bodyMediumFamily;

  TextStyle get bodyMedium;

  String get bodySmallFamily;

  TextStyle get bodySmall;
}

class MobileTypography extends Typography {
  MobileTypography(this.theme);

  final FlutterFlowTheme theme;

  String get displayLargeFamily => 'inter';

  TextStyle get displayLarge => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 64.0,
      );

  String get displayMediumFamily => 'inter';

  TextStyle get displayMedium => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 44.0,
      );

  String get displaySmallFamily => 'inter';

  TextStyle get displaySmall => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 36.0,
      );

  String get headlineLargeFamily => 'inter';

  TextStyle get headlineLarge => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 32.0,
      );

  String get headlineMediumFamily => 'inter';

  TextStyle get headlineMedium => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 24.0,
      );

  String get headlineSmallFamily => 'inter';

  TextStyle get headlineSmall => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 24.0,
      );

  String get titleLargeFamily => 'inter';

  TextStyle get titleLarge => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 22.0,
      );

  String get titleMediumFamily => 'Readex Pro';

  TextStyle get titleMedium => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.info,
        fontWeight: FontWeight.normal,
        fontSize: 18.0,
      );

  String get titleSmallFamily => 'Readex Pro';

  TextStyle get titleSmall => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 16.0,
      );

  String get labelLargeFamily => 'Readex Pro';

  TextStyle get labelLarge => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.secondaryText,
        fontWeight: FontWeight.normal,
        fontSize: 16.0,
      );

  String get labelMediumFamily => 'Readex Pro';

  TextStyle get labelMedium => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.secondaryText,
        fontWeight: FontWeight.normal,
        fontSize: 14.0,
      );

  String get labelSmallFamily => 'Readex Pro';

  TextStyle get labelSmall => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.secondaryText,
        fontWeight: FontWeight.normal,
        fontSize: 12.0,
      );

  String get bodyLargeFamily => 'Readex Pro';

  TextStyle get bodyLarge => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 16.0,
      );

  String get bodyMediumFamily => 'Readex Pro';

  TextStyle get bodyMedium => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 14.0,
      );

  String get bodySmallFamily => 'Readex Pro';

  TextStyle get bodySmall => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 12.0,
      );
}

class TabletTypography extends Typography {
  TabletTypography(this.theme);

  final FlutterFlowTheme theme;

  String get displayLargeFamily => 'inter';

  TextStyle get displayLarge => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 64.0,
      );

  String get displayMediumFamily => 'inter';

  TextStyle get displayMedium => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 44.0,
      );

  String get displaySmallFamily => 'inter';

  TextStyle get displaySmall => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 36.0,
      );

  String get headlineLargeFamily => 'inter';

  TextStyle get headlineLarge => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 32.0,
      );

  String get headlineMediumFamily => 'inter';

  TextStyle get headlineMedium => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 24.0,
      );

  String get headlineSmallFamily => 'inter';

  TextStyle get headlineSmall => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 24.0,
      );

  String get titleLargeFamily => 'inter';

  TextStyle get titleLarge => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 22.0,
      );

  String get titleMediumFamily => 'Readex Pro';

  TextStyle get titleMedium => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.info,
        fontWeight: FontWeight.normal,
        fontSize: 18.0,
      );

  String get titleSmallFamily => 'Readex Pro';

  TextStyle get titleSmall => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 16.0,
      );

  String get labelLargeFamily => 'Readex Pro';

  TextStyle get labelLarge => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.secondaryText,
        fontWeight: FontWeight.normal,
        fontSize: 16.0,
      );

  String get labelMediumFamily => 'Readex Pro';

  TextStyle get labelMedium => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.secondaryText,
        fontWeight: FontWeight.normal,
        fontSize: 14.0,
      );

  String get labelSmallFamily => 'Readex Pro';

  TextStyle get labelSmall => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.secondaryText,
        fontWeight: FontWeight.normal,
        fontSize: 12.0,
      );

  String get bodyLargeFamily => 'Readex Pro';

  TextStyle get bodyLarge => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 16.0,
      );

  String get bodyMediumFamily => 'Readex Pro';

  TextStyle get bodyMedium => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 14.0,
      );

  String get bodySmallFamily => 'Readex Pro';

  TextStyle get bodySmall => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 12.0,
      );
}

class DesktopTypography extends Typography {
  DesktopTypography(this.theme);

  final FlutterFlowTheme theme;

  String get displayLargeFamily => 'inter';

  TextStyle get displayLarge => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 64.0,
      );

  String get displayMediumFamily => 'inter';

  TextStyle get displayMedium => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 44.0,
      );

  String get displaySmallFamily => 'inter';

  TextStyle get displaySmall => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 36.0,
      );

  String get headlineLargeFamily => 'inter';

  TextStyle get headlineLarge => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.w600,
        fontSize: 32.0,
      );

  String get headlineMediumFamily => 'inter';

  TextStyle get headlineMedium => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 24.0,
      );

  String get headlineSmallFamily => 'inter';

  TextStyle get headlineSmall => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 24.0,
      );

  String get titleLargeFamily => 'inter';

  TextStyle get titleLarge => GoogleFonts.getFont(
        'inter',
        color: theme.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 22.0,
      );

  String get titleMediumFamily => 'Readex Pro';

  TextStyle get titleMedium => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.info,
        fontWeight: FontWeight.normal,
        fontSize: 18.0,
      );

  String get titleSmallFamily => 'Readex Pro';

  TextStyle get titleSmall => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.primaryText,
        fontWeight: FontWeight.w500,
        fontSize: 16.0,
      );

  String get labelLargeFamily => 'Readex Pro';

  TextStyle get labelLarge => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.secondaryText,
        fontWeight: FontWeight.normal,
        fontSize: 16.0,
      );

  String get labelMediumFamily => 'Readex Pro';

  TextStyle get labelMedium => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.secondaryText,
        fontWeight: FontWeight.normal,
        fontSize: 14.0,
      );

  String get labelSmallFamily => 'Readex Pro';

  TextStyle get labelSmall => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.secondaryText,
        fontWeight: FontWeight.normal,
        fontSize: 12.0,
      );

  String get bodyLargeFamily => 'Readex Pro';

  TextStyle get bodyLarge => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 16.0,
      );

  String get bodyMediumFamily => 'Readex Pro';

  TextStyle get bodyMedium => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 14.0,
      );

  String get bodySmallFamily => 'Readex Pro';

  TextStyle get bodySmall => GoogleFonts.getFont(
        'Readex Pro',
        color: theme.primaryText,
        fontWeight: FontWeight.normal,
        fontSize: 12.0,
      );
}

// class DarkModeTheme extends FlutterFlowTheme {
//   @Deprecated('Use primary instead')
//   Color get primaryColor => primary;
//
//   @Deprecated('Use secondary instead')
//   Color get secondaryColor => secondary;
//
//   @Deprecated('Use tertiary instead')
//   Color get tertiaryColor => tertiary;
//
//   late Color primary = const Color(0xFF4B39EF);
//   late Color secondary = const Color(0xFF39D2C0);
//   late Color tertiary = const Color(0xFFEE8B60);
//   late Color alternate = const Color(0xFF262D34);
//   late Color primaryText = const Color(0xFFFFFFFF);
//   late Color secondaryText = const Color(0xFF95A1AC);
//   late Color primaryBackground = const Color(0xFF1D2428);
//   late Color secondaryBackground = const Color(0xFF14181B);
//   late Color accent1 = const Color(0x4C4B39EF);
//   late Color accent2 = const Color(0x4D39D2C0);
//   late Color accent3 = const Color(0x4DEE8B60);
//   late Color accent4 = const Color(0xB2262D34);
//   late Color success = const Color(0xFF249689);
//   late Color warning = const Color(0xFFF9CF58);
//   late Color error = const Color(0xFFFF5963);
//   late Color info = const Color(0xFFFFFFFF);
//   late Color borderPrimary = const Color(0x00000000);
// }

class DarkModeTheme extends FlutterFlowTheme {
  @Deprecated('Use primary instead')
  Color get primaryColor => primary;

  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;

  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  late Color secondaryBackground = const Color(0xFFEEBF2B);
  late Color primaryBackground = const Color(0xFFFDF2CB);
  late Color onPrimary = const Color(0xFFFFFFFF);
  late Color secondary = const Color(0xFFFFFDF1);
  late Color primary = const Color(0xFF7088D7);
  late Color primaryText = const Color(0xFF333333);
  late Color accent1 = const Color(0xFFEEBF2B);
  late Color error = const Color(0xFFFF5963);
  late Color success = const Color(0xFF1BB100);
  late Color outline = const Color(0xFFB6B6B6);
  late Color tertiary = const Color(0xFFFFFFFF);
  late Color borderPrimary = const Color(0x00000000);

  //-----------以上有符合設計guideline-----------
  late Color alternate = const Color(0xFFE0E3E7);

  //Neutral/800
  late Color secondaryText = const Color(0xFF7F7F7F);
  late Color accent2 = const Color(0x4D39D2C0);
  late Color accent3 = const Color(0x4DEE8B60);
  late Color accent4 = const Color(0xCCFFFFFF);
  late Color warning = const Color(0xFFF9CF58);
  late Color info = const Color(0xFFFFFFFF);
  late double spaceMedium = 16;
  late double spaceLarge = 32;
  late double spaceXLarge = 64;
  late double spaceXXLarge = 128;
  late double radiusSmall = 16;
  late double radiusMedium = 32;

  late double textHeadlineSize = 60;
  late double textTitleSize = 40;
  late double textBody1Size = 24;
  late double textBody2Size = 20;
  late double textButtonSize = 24;
}

extension TextStyleHelper on TextStyle {
  TextStyle override({
    String? fontFamily,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    FontStyle? fontStyle,
    bool useGoogleFonts = true,
    TextDecoration? decoration,
    double? lineHeight,
    List<Shadow>? shadows,
  }) =>
      useGoogleFonts
          ? GoogleFonts.getFont(
              fontFamily!,
              color: color ?? this.color,
              fontSize: fontSize ?? this.fontSize,
              letterSpacing: letterSpacing ?? this.letterSpacing,
              fontWeight: fontWeight ?? this.fontWeight,
              fontStyle: fontStyle ?? this.fontStyle,
              decoration: decoration,
              height: lineHeight,
              shadows: shadows,
            )
          : copyWith(
              fontFamily: fontFamily,
              color: color,
              fontSize: fontSize,
              letterSpacing: letterSpacing,
              fontWeight: fontWeight,
              fontStyle: fontStyle,
              decoration: decoration,
              height: lineHeight,
              shadows: shadows,
            );
}
