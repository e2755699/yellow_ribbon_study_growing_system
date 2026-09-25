import 'package:flutter/material.dart';
import '../system_theme.dart';

/// 單一選項的膠囊分段控制。
///
/// 用於少量互斥選項（檢視模式、出缺勤狀態等），取代下拉選單或 ToggleButtons：
/// 所有選項一眼可見、一次點擊完成切換。選中項以實心膠囊呈現，
/// 顏色可依選項語意（`toneKey`，例如 success／warning／error）變化。
class SystemPillOption<T> {
  const SystemPillOption(
      {required this.value, required this.label, this.icon, this.toneKey});
  final T value;
  final String label;
  final IconData? icon;

  /// SystemTheme 語意色 key；null 表示使用品牌 primary。
  final String? toneKey;
}

class SystemPillSegment<T> extends StatelessWidget {
  const SystemPillSegment(
      {super.key,
      required this.options,
      required this.selected,
      required this.onChanged,
      this.dense = false});
  final List<SystemPillOption<T>> options;
  final T selected;
  final ValueChanged<T>? onChanged;

  /// 較緊湊的字級與內距，用於卡片內的狀態選擇；觸控高度仍保持 44。
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    final gap = ds.metric('spaceSmall');
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: [
        for (final option in options)
          _Pill<T>(
              option: option,
              selected: option.value == selected,
              dense: dense,
              onTap: onChanged == null ? null : () => onChanged!(option.value)),
      ],
    );
  }
}

class _Pill<T> extends StatelessWidget {
  const _Pill(
      {required this.option,
      required this.selected,
      required this.dense,
      required this.onTap});
  final SystemPillOption<T> option;
  final bool selected;
  final bool dense;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    final tone =
        option.toneKey == null ? ds.primary : ds.color(option.toneKey!);
    // 品牌色以 onPrimary 作前景；語意色在 Light 用表面白、Dark 用深底，確保對比。
    final onTone = option.toneKey == null
        ? ds.onPrimary
        : ds.color(ds.dark ? 'primaryBackground' : 'secondaryBackground');
    final foreground = selected ? onTone : ds.color('primaryText');
    final background = selected ? tone : ds.color('secondaryBackground');
    final side =
        BorderSide(color: selected ? tone : ds.color('border').withOpacity(.7));
    final fontSize = dense ? ds.metric('labelSize') : ds.metric('bodySize');
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: background,
        shape: StadiumBorder(side: side),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          hoverColor: tone.withOpacity(ds.metric('hoverDarken')),
          highlightColor: tone.withOpacity(ds.metric('pressedDarken')),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: ds.metric(dense ? 'spaceSmall' : 'spaceMedium') +
                      (dense ? 4 : 0)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (option.icon != null) ...[
                  Icon(option.icon, size: fontSize + 4, color: foreground),
                  SizedBox(width: ds.metric('spaceSmall') * .75),
                ],
                Text(option.label,
                    style: TextStyle(
                        fontSize: fontSize,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: foreground)),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
