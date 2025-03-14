import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';

/// 月份筛选下拉菜单
class MonthFilterDropdownMenu extends StatefulWidget {
  final ValueNotifier<DateTime?> monthFilterNotifier;
  final DateTime earliestDate;
  final DateTime latestDate;
  final String labelPrefix;

  const MonthFilterDropdownMenu({
    super.key, 
    required this.monthFilterNotifier,
    required this.earliestDate,
    required this.latestDate,
    this.labelPrefix = '月份',
  });

  @override
  State<MonthFilterDropdownMenu> createState() => _MonthFilterDropdownMenuState();
}

class _MonthFilterDropdownMenuState extends State<MonthFilterDropdownMenu> {
  late List<MonthOption> _options;
  late MonthOption _selectedOption;

  @override
  void initState() {
    super.initState();
    _updateOptions();
    
    // 监听值变化
    widget.monthFilterNotifier.addListener(_onValueChanged);
  }
  
  @override
  void didUpdateWidget(MonthFilterDropdownMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.earliestDate != widget.earliestDate || 
        oldWidget.latestDate != widget.latestDate) {
      _updateOptions();
    }
  }
  
  @override
  void dispose() {
    widget.monthFilterNotifier.removeListener(_onValueChanged);
    super.dispose();
  }
  
  // 当值变化时更新选中项
  void _onValueChanged() {
    setState(() {
      _updateSelectedOption();
    });
  }
  
  // 更新选项列表
  void _updateOptions() {
    // 生成月份选项列表
    _options = _generateMonthOptions();
    
    // 添加"全部"选项
    _options.insert(0, MonthOption(null, '${widget.labelPrefix} : 全部'));
    
    // 更新选中项
    _updateSelectedOption();
  }
  
  // 更新选中项
  void _updateSelectedOption() {
    final currentValue = widget.monthFilterNotifier.value;
    
    if (currentValue == null) {
      // 选中"全部"选项
      _selectedOption = _options.first;
    } else {
      // 查找匹配的月份选项
      final matchingOption = _options.firstWhere(
        (option) => option.date != null && 
                   option.date!.year == currentValue.year && 
                   option.date!.month == currentValue.month,
        orElse: () => _options.first, // 如果没有匹配项，默认选中"全部"
      );
      
      _selectedOption = matchingOption;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: FlutterFlowTheme.of(context).primaryBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButton<MonthOption>(
        value: _selectedOption,
        isExpanded: true,
        underline: const SizedBox(), // 移除下划线
        icon: const Icon(Icons.arrow_drop_down),
        items: _options.map((option) {
          return DropdownMenuItem<MonthOption>(
            value: option,
            child: Text(option.label),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            setState(() {
              _selectedOption = newValue;
              // 更新通知器的值
              print('选择月份: ${newValue.date}');
              widget.monthFilterNotifier.value = newValue.date;
            });
          }
        },
      ),
    );
  }

  /// 生成月份选项列表
  List<MonthOption> _generateMonthOptions() {
    List<MonthOption> options = [];
    
    // 确保日期范围有效
    if (widget.earliestDate.isAfter(widget.latestDate)) {
      return options;
    }
    
    // 将日期调整为月份的第一天
    DateTime startDate = DateTime(widget.earliestDate.year, widget.earliestDate.month, 1);
    DateTime endDate = DateTime(widget.latestDate.year, widget.latestDate.month, 1);
    
    // 生成月份选项
    DateTime currentDate = endDate;
    while (!currentDate.isBefore(startDate)) {
      options.add(MonthOption(
        currentDate,
        '${widget.labelPrefix} : ${DateFormat('yyyy年MM月').format(currentDate)}',
      ));
      
      // 移动到上一个月
      currentDate = DateTime(
        currentDate.month > 1 ? currentDate.year : currentDate.year - 1,
        currentDate.month > 1 ? currentDate.month - 1 : 12,
        1,
      );
    }
    
    return options;
  }
}

/// 月份选项
class MonthOption {
  final DateTime? date;
  final String label;

  MonthOption(this.date, this.label);
} 