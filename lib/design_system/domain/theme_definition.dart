import 'dart:convert';
import 'dart:math' as math;

/// Backend- and Flutter-independent wire contract. All colors are opaque sRGB hex.
class ThemeDefinition {
  ThemeDefinition(
      {required this.id,
      required this.name,
      required Map<String, String> light,
      required Map<String, String> dark,
      required Map<String, double> metrics,
      this.revision = 0})
      : light = Map.unmodifiable(light),
        dark = Map.unmodifiable(dark),
        metrics = Map.unmodifiable(metrics);

  final String id;
  final String name;
  final int revision;
  final Map<String, String> light;
  final Map<String, String> dark;
  final Map<String, double> metrics;
  static const schemaVersion = 1;
  static bool validId(String id) =>
      RegExp(r'^[a-zA-Z0-9][a-zA-Z0-9_-]{0,79}$').hasMatch(id);
  static const colorGroups = {
    '品牌色 Brand': [
      'primary',
      'onPrimary',
      'detail',
      'secondary',
      'tertiary',
      'alternate'
    ],
    '介面色 Utility': [
      'primaryText',
      'secondaryText',
      'primaryBackground',
      'secondaryBackground',
      'border'
    ],
    '輔助色 Accent': ['accent1', 'accent2', 'accent3', 'accent4'],
    '狀態色 Semantic': ['success', 'error', 'warning', 'info'],
  };
  static List<String> get colorKeys =>
      colorGroups.values.expand((keys) => keys).toList();
  static const metricRanges = <String, (double, double)>{
    'headingSize': (24, 48),
    'titleSize': (18, 32),
    'bodySize': (14, 22),
    'labelSize': (12, 18),
    'buttonSize': (20, 28),
    'spaceSmall': (4, 16),
    'spaceMedium': (8, 32),
    'spaceLarge': (16, 48),
    'radiusSmall': (0, 24),
    'radiusMedium': (0, 40),
    'hoverDarken': (0.08, 0.12),
    'pressedDarken': (0.08, 0.12),
  };

  ThemeDefinition copyWith(
          {String? name,
          Map<String, String>? light,
          Map<String, String>? dark,
          Map<String, double>? metrics,
          int? revision}) =>
      ThemeDefinition(
          id: id,
          name: name ?? this.name,
          light: light ?? this.light,
          dark: dark ?? this.dark,
          metrics: metrics ?? this.metrics,
          revision: revision ?? this.revision);

  ThemeDefinition withColor(bool isDark, String key, String hex) {
    if (!colorKeys.contains(key) || !validHex(hex)) {
      throw const FormatException('請輸入 #RRGGBB 色碼');
    }
    final colors = {...(isDark ? dark : light), key: hex.toUpperCase()};
    return copyWith(
        light: isDark ? null : colors, dark: isDark ? colors : null);
  }

  ThemeDefinition duplicate({required String id, required String name}) =>
      ThemeDefinition(
          id: id,
          name: name.trim(),
          light: light,
          dark: dark,
          metrics: metrics);

  static bool validHex(String value) =>
      RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(value);
  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'name': name,
        'revision': revision,
        'light': light,
        'dark': dark,
        'metrics': metrics
      };
  String get fingerprint => jsonEncode(toJson()..remove('revision'));

  factory ThemeDefinition.fromJson(String id, Map<String, dynamic> json) {
    if (json['schemaVersion'] != schemaVersion) {
      throw const FormatException('不支援的主題版本');
    }
    final theme = ThemeDefinition(
        id: id,
        name: json['name'] as String,
        revision: json['revision'] as int,
        light: Map<String, String>.from(json['light'] as Map),
        dark: Map<String, String>.from(json['dark'] as Map),
        metrics: (json['metrics'] as Map).map((key, value) =>
            MapEntry(key as String, (value as num).toDouble())));
    final errors = theme.validationErrors;
    if (errors.isNotEmpty) throw FormatException(errors.join('；'));
    return theme;
  }

  List<String> get validationErrors {
    final errors = <String>[];
    if (!validId(id) ||
        name.trim().isEmpty ||
        name.length > 40 ||
        revision < 0) {
      errors.add('主題識別或名稱無效');
    }
    for (final entry in {'淺色': light, '深色': dark}.entries) {
      final colors = entry.value;
      if (colors.length != colorKeys.length ||
          colorKeys.any((key) => !validHex(colors[key] ?? ''))) {
        errors.add('${entry.key}色票不完整');
        continue;
      }
      if (contrast(colors['primary']!, colors['onPrimary']!) < 3) {
        errors.add('${entry.key}主按鈕對比不足 3:1');
      }
      if (contrast(colors['primaryText']!, colors['primaryBackground']!) <
              4.5 ||
          contrast(colors['primaryText']!, colors['secondaryBackground']!) <
              4.5) errors.add('${entry.key}內文對比不足 4.5:1');
      if (contrast(colors['secondaryText']!, colors['primaryBackground']!) <
              4.5 ||
          contrast(colors['secondaryText']!, colors['secondaryBackground']!) <
              4.5) {
        errors.add('${entry.key}次要文字對比不足 4.5:1');
      }
    }
    if (metrics.length != metricRanges.length) errors.add('尺寸設定不完整');
    for (final entry in metricRanges.entries) {
      final value = metrics[entry.key];
      if (value == null ||
          !value.isFinite ||
          value < entry.value.$1 ||
          value > entry.value.$2) errors.add('${entry.key} 超出允許範圍');
    }
    if ((metrics['pressedDarken'] ?? 0) < (metrics['hoverDarken'] ?? 0)) {
      errors.add('按下狀態需比 hover 更深');
    }
    return errors;
  }

  static double contrast(String a, String b) {
    double luminance(String hex) {
      final channels = [1, 3, 5]
          .map((offset) =>
              int.parse(hex.substring(offset, offset + 2), radix: 16) / 255)
          .map((v) => v <= 0.04045
              ? v / 12.92
              : math.pow((v + 0.055) / 1.055, 2.4).toDouble())
          .toList();
      return channels[0] * 0.2126 + channels[1] * 0.7152 + channels[2] * 0.0722;
    }

    final x = luminance(a), y = luminance(b);
    return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
  }
}
