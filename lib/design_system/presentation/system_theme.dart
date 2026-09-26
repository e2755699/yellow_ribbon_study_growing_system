import 'package:flutter/material.dart';
import '../domain/theme_definition.dart';
import '../domain/theme_defaults.dart';

Color tokenColor(String hex) =>
    Color(int.parse('FF${hex.substring(1)}', radix: 16));

class SystemTheme extends ThemeExtension<SystemTheme> {
  const SystemTheme(this.definition, this.dark);
  final ThemeDefinition definition;
  final bool dark;
  static SystemTheme of(BuildContext context) =>
      Theme.of(context).extension<SystemTheme>() ??
      SystemTheme(defaultDesignThemes().first,
          Theme.of(context).brightness == Brightness.dark);

  BorderRadius get cardRadius => BorderRadius.circular(metric('radiusMedium'));
  BorderSide get cardBorder =>
      BorderSide(color: color('border').withOpacity(.45));
  BoxDecoration get cardDecoration => BoxDecoration(
      color: color('secondaryBackground'),
      borderRadius: cardRadius,
      border: Border.fromBorderSide(cardBorder));
  // 淺底一律走暖色階（accent1），不再以 primary 加透明度，避免焦糖主色淺化後偏粉紅。
  Color get accentSurface => surfaceTone(100);
  Color get brandSurface => surfaceTone(50);

  /// 由 primary 推算的品牌色階，所有主題（含自訂）自動具備，不需擴充儲存 schema。
  ///
  /// - 50／100／200：由淺到深的品牌底色，疊在卡片表面上（頁首、選取、標籤底）。
  /// - 700：強調文字／圖示，Light 壓暗、Dark 提亮，維持對表面 4.5:1 以上。
  Color brandTone(int level) {
    final surface = color('secondaryBackground');
    if (level >= 700) {
      return Color.lerp(
          primary, dark ? Colors.white : Colors.black, dark ? .45 : .35)!;
    }
    final alpha = switch (level) {
      <= 50 => dark ? .10 : .07,
      <= 100 => dark ? .18 : .14,
      _ => dark ? .30 : .26,
    };
    return Color.alphaBlend(primary.withOpacity(alpha), surface);
  }

  /// 頁首色塊的漸層，只由既有背景 token 組成：Light 從 `primaryBackground`
  /// （App 的米黃底）漸變到頁面底色 `secondary`；Dark 以少量 `accent1` 暖色
  /// 疊在 `secondary` 上。不從 primary 推算，避免主色淺化後偏離主題色調。
  List<Color> get headerGradient => [
        dark
            ? Color.alphaBlend(
                color('accent1').withOpacity(.14), color('secondary'))
            : color('primaryBackground'),
        color('secondary'),
      ];

  /// 暖色淺底階（標籤底、頭像環、圓形圖示底、狀態插圖），以 `accent1`
  /// （黃絲帶色）疊在卡片表面上：50 最淺、100 次之、200 作為邊框。
  /// 前景文字／圖示搭配 `brandTone(700)`。
  Color surfaceTone(int level) {
    final alpha = switch (level) {
      <= 50 => dark ? .10 : .14,
      <= 100 => dark ? .16 : .24,
      _ => dark ? .30 : .45,
    };
    return Color.alphaBlend(
        color('accent1').withOpacity(alpha), color('secondaryBackground'));
  }

  /// 語意狀態的柔和底色（膠囊、標籤），與前景 `color(key)` 成對使用。
  Color statusSurface(String key) => Color.alphaBlend(
      color(key).withOpacity(dark ? .22 : .12), color('secondaryBackground'));
  Color color(String key) =>
      tokenColor((dark ? definition.dark : definition.light)[key]!);
  double metric(String key) => definition.metrics[key]!;
  Color get primary => color('primary');
  Color get onPrimary => color('onPrimary');
  Color backgroundFor(Set<WidgetState> states) {
    final amount = states.contains(WidgetState.pressed)
        ? metric('pressedDarken')
        : states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)
            ? metric('hoverDarken')
            : 0.0;
    return Color.fromARGB(
        255,
        (primary.red * (1 - amount)).round(),
        (primary.green * (1 - amount)).round(),
        (primary.blue * (1 - amount)).round());
  }

  ThemeData materialTheme() {
    final brightness = dark ? Brightness.dark : Brightness.light;
    final base = ThemeData(brightness: brightness, useMaterial3: false);
    final text = base.textTheme
        .apply(
            bodyColor: color('primaryText'), displayColor: color('primaryText'))
        .copyWith(
          headlineMedium: TextStyle(
              fontSize: metric('headingSize'),
              fontWeight: FontWeight.w700,
              color: color('primaryText')),
          titleLarge: TextStyle(
              fontSize: metric('titleSize'),
              fontWeight: FontWeight.w700,
              color: color('primaryText')),
          bodyMedium: TextStyle(
              fontSize: metric('bodySize'), color: color('primaryText')),
          labelMedium: TextStyle(
              fontSize: metric('labelSize'), color: color('secondaryText')),
        );
    return base.copyWith(
      primaryColor: primary,
      scaffoldBackgroundColor: color('primaryBackground'),
      cardColor: color('secondaryBackground'),
      dividerColor: color('border'),
      textTheme: text,
      colorScheme: base.colorScheme.copyWith(
          primary: primary,
          onPrimary: onPrimary,
          secondary: color('secondary'),
          surface: color('secondaryBackground'),
          onSurface: color('primaryText'),
          error: color('error')),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        foregroundColor: onPrimary,
        textStyle: TextStyle(
            fontSize: metric('buttonSize'), fontWeight: FontWeight.w700),
        minimumSize: const Size(44, 48),
        elevation: 0,
        padding: EdgeInsets.all(metric('spaceMedium')),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(metric('radiusSmall'))),
      ).copyWith(
              backgroundColor: WidgetStateProperty.resolveWith(backgroundFor),
              overlayColor: const WidgetStatePropertyAll(Colors.transparent))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
              foregroundColor: color('detail'),
              minimumSize: const Size(44, 48),
              textStyle: TextStyle(
                  fontSize: metric('bodySize'), fontWeight: FontWeight.w600),
              side: BorderSide(color: color('detail')),
              padding: EdgeInsets.symmetric(
                  horizontal: metric('spaceMedium'),
                  vertical: metric('spaceSmall')),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(metric('radiusSmall'))))),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
              foregroundColor: color('detail'),
              minimumSize: const Size(44, 44),
              textStyle: TextStyle(
                  fontSize: metric('labelSize'), fontWeight: FontWeight.w600))),
      iconTheme: IconThemeData(color: color('detail')),
      // Material 預設的彈出表面、選單與勾選元件不會自動讀 token；
      // 未設定時 Dark 會出現白字配淺色表面或看不見的勾選狀態。
      canvasColor: color('secondaryBackground'),
      unselectedWidgetColor: color('secondaryText'),
      hintColor: color('secondaryText'),
      disabledColor: color('secondaryText').withOpacity(.6),
      textSelectionTheme: TextSelectionThemeData(
          cursorColor: primary,
          selectionColor: primary.withOpacity(.3),
          selectionHandleColor: primary),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: primary),
      checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) => states
                  .contains(WidgetState.selected)
              ? primary
                  .withOpacity(states.contains(WidgetState.disabled) ? .4 : 1)
              : Colors.transparent),
          checkColor: WidgetStatePropertyAll(onPrimary),
          side: BorderSide(color: color('secondaryText'), width: 2)),
      radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? primary
                  : color('secondaryText'))),
      switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? primary
                  : color('alternate')),
          trackColor: WidgetStateProperty.resolveWith((states) =>
              states.contains(WidgetState.selected)
                  ? primary.withOpacity(.45)
                  : color('border'))),
      dialogTheme: DialogThemeData(
          backgroundColor: color('secondaryBackground'),
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: cardRadius),
          titleTextStyle: TextStyle(
              fontSize: metric('titleSize'),
              fontWeight: FontWeight.w700,
              color: color('primaryText')),
          contentTextStyle: TextStyle(
              fontSize: metric('bodySize'), color: color('primaryText'))),
      popupMenuTheme: PopupMenuThemeData(
          color: color('secondaryBackground'),
          surfaceTintColor: Colors.transparent,
          textStyle: TextStyle(
              fontSize: metric('bodySize'), color: color('primaryText')),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(metric('radiusSmall')))),
      dropdownMenuTheme: DropdownMenuThemeData(
          textStyle: TextStyle(
              fontSize: metric('bodySize'), color: color('primaryText')),
          menuStyle: MenuStyle(
              backgroundColor:
                  WidgetStatePropertyAll(color('secondaryBackground')),
              surfaceTintColor:
                  const WidgetStatePropertyAll(Colors.transparent))),
      snackBarTheme: SnackBarThemeData(
          backgroundColor: color('primaryText'),
          contentTextStyle: TextStyle(
              fontSize: metric('bodySize'),
              color: color('secondaryBackground')),
          actionTextColor: color('secondaryBackground'),
          behavior: SnackBarBehavior.floating),
      bottomSheetTheme: BottomSheetThemeData(
          backgroundColor: color('secondaryBackground'),
          surfaceTintColor: Colors.transparent),
      datePickerTheme: DatePickerThemeData(
          backgroundColor: color('secondaryBackground'),
          surfaceTintColor: Colors.transparent,
          headerBackgroundColor: primary,
          headerForegroundColor: onPrimary),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: color('secondary'),
          labelStyle: TextStyle(
              color: color('secondaryText'), fontSize: metric('labelSize')),
          floatingLabelStyle: TextStyle(
              color: color('secondaryText'), fontSize: metric('labelSize')),
          hintStyle: TextStyle(color: color('secondaryText')),
          contentPadding: EdgeInsets.all(metric('spaceMedium')),
          // 底色與卡片接近，邊框必須明確給色，不能落回 Material 的 38% hairline。
          border: _inputBorder(color('border')),
          enabledBorder: _inputBorder(color('border')),
          focusedBorder: _inputBorder(primary, width: 2),
          errorBorder: _inputBorder(color('error')),
          focusedErrorBorder: _inputBorder(color('error'), width: 2),
          disabledBorder: _inputBorder(color('border').withOpacity(.5))),
      extensions: [this],
    );
  }

  OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
          borderRadius: BorderRadius.circular(metric('radiusSmall')),
          borderSide: BorderSide(color: color, width: width));

  @override
  SystemTheme copyWith({ThemeDefinition? definition, bool? dark}) =>
      SystemTheme(definition ?? this.definition, dark ?? this.dark);
  @override
  SystemTheme lerp(covariant SystemTheme? other, double t) =>
      other == null || t < 0.5 ? this : other;
}
