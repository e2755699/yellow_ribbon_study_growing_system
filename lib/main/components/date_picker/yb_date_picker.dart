import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';

/// 日期选择器组件
///
/// 以 InputDecorator 呈現，外觀（底色、邊框、浮動標籤）與同列的下拉選單、
/// 搜尋欄共用目前的 inputDecorationTheme；放在 SystemPageHeader 內即為白色欄位。
/// 整個欄位都是可點範圍，高度與其他輸入欄位一致（至少 48）。
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
    return Semantics(
      button: true,
      label: '$labelText ${DateFormat('yyyy-MM-dd').format(selectedDate)}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(ds.metric('radiusSmall')),
        onTap: () => _selectDate(context),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: labelText,
            suffixIcon: Icon(Icons.calendar_today_rounded,
                size: 20, color: ds.color('detail')),
          ),
          child: Text(
            DateFormat('yyyy-MM-dd').format(selectedDate),
            style: TextStyle(
                fontSize: ds.metric('bodySize'),
                color: ds.color('primaryText')),
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
