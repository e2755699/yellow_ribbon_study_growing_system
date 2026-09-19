import 'package:flutter/material.dart';
import '../../../design_system/presentation/system_theme.dart';

/// A read-only achievement count, shared by student cards and avatars.
class YellowRibbonCountBadge extends StatelessWidget {
  const YellowRibbonCountBadge(
      {super.key, required this.count, this.size, this.showLabel = true});
  final int? count;
  final double? size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    final earned = count != null && count! > 0;
    final foreground = ds.color(earned ? 'warning' : 'secondaryText');
    final fontSize = size ?? ds.metric('labelSize');
    final spacing = ds.metric('spaceSmall');
    return Semantics(
      label: count == null ? '黃絲帶數量載入中' : '黃絲帶 $count 枚',
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: spacing * 1.25, vertical: spacing * .65),
        decoration: ShapeDecoration(
          color: Color.alphaBlend(
            earned
                ? ds.color('accent1').withOpacity(.14)
                : ds.color('secondaryText').withOpacity(.055),
            ds.color('secondaryBackground'),
          ),
          shape: StadiumBorder(
              side: BorderSide(
                  color: foreground.withOpacity(earned ? .18 : .12))),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.workspace_premium_rounded,
              size: fontSize + 4, color: foreground),
          SizedBox(width: spacing * .65),
          if (showLabel) ...[
            Text('黃絲帶',
                style: TextStyle(
                    fontSize: fontSize, height: 1.2, color: foreground)),
            SizedBox(width: spacing),
          ],
          Text(count?.toString() ?? '—',
              style: TextStyle(
                fontSize: fontSize,
                height: 1.2,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: foreground,
              )),
        ]),
      ),
    );
  }
}
