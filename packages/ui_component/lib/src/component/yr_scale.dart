import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gap/gap.dart';
import 'package:ui_component/src/design_token.dart';
import 'package:ui_component/src/component/yr_form_warp.dart';
import 'package:ui_component/src/component/yr_text.dart';
import 'package:ui_component/src/cubit/yr_theme/yr_theme_cubit.dart';

/// YrScale是一个5度量表组件，用于表示1-5的评分或者满意度等
class YrScale extends StatelessWidget {
  /// 标题文本
  final String label;

  /// 左侧文本描述（例如"非常不满意"）
  final String leftLabel;

  /// 右侧文本描述（例如"非常满意"）
  final String rightLabel;

  /// 当前选中的值（1-5）
  final ValueNotifier<int> value;

  /// 是否显示数字标签（1,2,3,4,5）
  final bool showNumbers;

  /// 是否禁用此组件
  final bool isDisabled;

  /// 值变化回调
  final Function(int)? onChanged;

  /// 创建一个5度量表
  YrScale({
    super.key,
    required this.label,
    this.leftLabel = '非常不满意',
    this.rightLabel = '非常满意',
    int initialValue = 3,
    this.showNumbers = true,
    this.isDisabled = false,
    this.onChanged,
  }) : value = ValueNotifier(initialValue);

  @override
  Widget build(BuildContext context) {
    final theme = context.read<YrThemeCubit>().state.theme;
    final activeColor = theme.color.text.active;
    final defaultColor = theme.color.text.defaulted;

    return YrFormWarp(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YrText(label),
          const Gap(8),
          Row(
            children: [
              YrText(
                leftLabel,
                color: defaultColor,
              ),
              Expanded(
                child: ValueListenableBuilder(
                  valueListenable: value,
                  builder: (context, currentValue, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(5, (index) {
                        final scaleValue = index + 1;
                        return Column(
                          children: [
                            if (showNumbers)
                              YrText(
                                '$scaleValue',
                                color: currentValue == scaleValue
                                    ? activeColor
                                    : defaultColor,
                              ),
                            Radio<int>(
                              value: scaleValue,
                              groupValue: currentValue,
                              activeColor: activeColor,
                              onChanged: isDisabled
                                  ? null
                                  : (newValue) {
                                      if (newValue != null) {
                                        value.value = newValue;
                                        onChanged?.call(newValue);
                                      }
                                    },
                            ),
                          ],
                        );
                      }),
                    );
                  },
                ),
              ),
              YrText(
                rightLabel,
                color: defaultColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
