import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/class_location.dart';

/// 據點篩選欄位：與學生名冊相同的下拉欄位外觀（浮動標籤「據點」），
/// 外觀由所在位置的 inputDecorationTheme 決定（頁首內為白色欄位）。
class ClassLocationFilterField extends StatelessWidget {
  const ClassLocationFilterField({super.key, required this.notifier});
  final ValueNotifier<ClassLocation> notifier;

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    final gap = ds.metric('spaceMedium');
    return ValueListenableBuilder<ClassLocation>(
      valueListenable: notifier,
      builder: (context, value, _) => DropdownButtonFormField<ClassLocation>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
            labelText: '據點',
            contentPadding:
                EdgeInsets.symmetric(horizontal: gap, vertical: gap)),
        items: [
          for (final place in ClassLocation.values)
            DropdownMenuItem(value: place, child: Text(place.name)),
        ],
        onChanged: (place) {
          if (place != null) notifier.value = place;
        },
      ),
    );
  }
}
