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
  Color get accentSurface => color('accent1').withOpacity(.16);
  Color get brandSurface => primary.withOpacity(.12);
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
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: color('secondary'),
          labelStyle: TextStyle(
              color: color('secondaryText'), fontSize: metric('labelSize')),
          contentPadding: EdgeInsets.all(metric('spaceMedium')),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(metric('radiusSmall')),
              borderSide: BorderSide(color: color('border')))),
      extensions: [this],
    );
  }

  @override
  SystemTheme copyWith({ThemeDefinition? definition, bool? dark}) =>
      SystemTheme(definition ?? this.definition, dark ?? this.dark);
  @override
  SystemTheme lerp(covariant SystemTheme? other, double t) =>
      other == null || t < 0.5 ? this : other;
}
