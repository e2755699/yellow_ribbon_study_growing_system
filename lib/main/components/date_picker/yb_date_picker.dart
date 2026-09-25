import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';

/// 日期选择器组件
///
/// 外觀取自 SystemTheme，與輸入欄位共用底色、邊框與圓角；整個欄位都是
/// 可點範圍（至少 48 高），寬度依內容而定，避免固定寬度截斷日期文字。
class YbDatePicker extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final String labelText;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const YbDatePicker({
    super.key,
    required this.selectedDate,
    required this.onDateChanged,
    this.labelText = '日期',
    this.firstDate,
    this.lastDate,
  });

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    final radius = BorderRadius.circular(ds.metric('radiusSmall'));
    return Material(
      color: ds.color('secondary'),
      shape: RoundedRectangleBorder(
          borderRadius: radius, side: BorderSide(color: ds.color('border'))),
      child: InkWell(
        borderRadius: radius,
        onTap: () => _selectDate(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: ds.metric('spaceMedium')),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$labelText: ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
                  style: TextStyle(
                      fontSize: ds.metric('bodySize'),
                      color: ds.color('primaryText')),
                ),
                SizedBox(width: ds.metric('spaceSmall')),
                Icon(Icons.calendar_today, size: 20, color: ds.color('detail')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    // 對話框沿用呼叫端 Theme（App 根部即為 SystemTheme），明暗與主題色一致。
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? today,
    );

    if (picked != null && picked != selectedDate) {
      onDateChanged(picked);
    }
  }
}
