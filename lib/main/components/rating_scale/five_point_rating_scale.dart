import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';

/// 五度量表組件
/// 用於顯示1-5的評分，支持只讀和可編輯兩種模式
class FivePointRatingScale extends StatelessWidget {
  /// 當前評分值 (1-5)
  final int value;

  /// 是否可編輯
  final bool isEditable;

  /// 評分變更時的回調
  final Function(int)? onChanged;

  /// 評分標題
  final String title;

  /// 顯示的標籤 (可選)
  final List<String>? labels;

  /// 評分顏色 (可選)
  final List<Color>? colors;

  const FivePointRatingScale({
    Key? key,
    required this.value,
    this.isEditable = true,
    this.onChanged,
    required this.title,
    this.labels,
    this.colors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 默認標籤
    final displayLabels = labels ?? ['很差', '差', '普通', '好', '優秀'];

    // 默認顏色
    final displayColors = colors ??
        [
          Colors.red,
          Colors.orange,
          Colors.amber,
          Colors.lightGreen,
          Colors.green,
        ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標題
        Row(
          children: [
            Text(
              '$title：',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 8),

            // 當前評分文字顯示
            if (!isEditable) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: displayColors[value - 1].withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  displayLabels[value - 1],
                  style: TextStyle(
                    color: displayColors[value - 1],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),

        // 評分星級顯示
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isEditable ? Colors.grey.withOpacity(0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: List.generate(5, (index) {
              final ratingValue = index + 1;
              final isSelected = ratingValue <= value;

              return GestureDetector(
                onTap: isEditable
                    ? () {
                        if (onChanged != null) {
                          onChanged!(ratingValue);
                        }
                      }
                    : null,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    child: Icon(
                      isSelected ? Icons.star : Icons.star_border,
                      color: isSelected ? displayColors[index] : Colors.grey.withOpacity(0.5),
                      size: isSelected ? 22 : 20,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

/// 可以通過 ValueNotifier 自動更新的五度量表
class ValueListenableFivePointRatingScale extends StatelessWidget {
  final ValueNotifier<int> ratingNotifier;
  final bool isEditable;
  final String title;
  final List<String>? labels;
  final List<Color>? colors;

  const ValueListenableFivePointRatingScale({
    Key? key,
    required this.ratingNotifier,
    this.isEditable = true,
    required this.title,
    this.labels,
    this.colors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ratingNotifier,
      builder: (context, value, _) {
        return FivePointRatingScale(
          value: value,
          isEditable: isEditable,
          onChanged: (newValue) {
            ratingNotifier.value = newValue;
          },
          title: title,
          labels: labels,
          colors: colors,
        );
      },
    );
  }
}
