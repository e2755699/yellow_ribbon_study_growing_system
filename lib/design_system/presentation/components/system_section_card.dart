import 'package:flutter/material.dart';
import '../system_theme.dart';

class SystemSectionCard extends StatelessWidget {
  const SystemSectionCard(
      {super.key,
      required this.title,
      required this.icon,
      required this.child,
      this.action});
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    final gap = ds.metric('spaceMedium');
    return Container(
        decoration: ds.cardDecoration,
        clipBehavior: Clip.antiAlias,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
              padding: EdgeInsets.fromLTRB(gap, gap / 2, gap, gap / 2),
              child: Row(children: [
                Icon(icon, color: ds.color('detail'), size: 22),
                SizedBox(width: gap / 2),
                Expanded(
                    child: Text(title,
                        style: TextStyle(
                            fontSize: ds.metric('bodySize'),
                            color: ds.color('primaryText'),
                            fontWeight: FontWeight.w700))),
                if (action != null) action! else const SizedBox(height: 44),
              ])),
          Divider(height: 1, color: ds.color('border').withOpacity(.35)),
          Padding(padding: EdgeInsets.all(gap), child: child),
        ]));
  }
}
