import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/excellent_character.dart';

/// 優秀品格標籤選擇器組件
///
/// 樣式依 docs/design-guideline.md：可點標籤為膠囊、至少 44 高；選中以暖色淺底
/// （surfaceTone）＋強調色字（brandTone 700）＋勾選圖示表達，不只靠顏色。
/// 「完成作業」選中時使用 success 語意色。
class CharacterTagSelector extends StatelessWidget {
  /// 已選中的標籤
  final List<ExcellentCharacter> selectedTags;

  /// 可用的標籤列表
  final List<ExcellentCharacter> availableTags;

  /// 自定義標籤列表
  final List<String> customTags;

  /// 選中標籤變更回調
  final Function(List<ExcellentCharacter>) onTagsChanged;

  /// 自定義標籤選中回調
  final Function(String)? onCustomTagSelected;

  /// 可否添加自定義標籤
  final bool enableCustomTagAdd;

  /// 是否顯示特殊標籤（完成作業和小幫手）
  final bool showSpecialTags;

  const CharacterTagSelector({
    Key? key,
    required this.selectedTags,
    required this.availableTags,
    this.customTags = const [],
    required this.onTagsChanged,
    this.onCustomTagSelected,
    this.enableCustomTagAdd = false,
    this.showSpecialTags = true,
  }) : super(key: key);

  void _toggle(ExcellentCharacter tag) {
    final updatedTags = List<ExcellentCharacter>.from(selectedTags);
    if (!updatedTags.remove(tag)) updatedTags.add(tag);
    onTagsChanged(updatedTags);
  }

  @override
  Widget build(BuildContext context) {
    final gap = SystemTheme.of(context).metric('spaceSmall');
    final regular = availableTags.where((tag) => !tag.isSpecialTag).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 特殊標籤區域（完成作業和小幫手）；窄卡片時自動換行。
        if (showSpecialTags)
          Padding(
            padding: EdgeInsets.only(bottom: gap * 1.5),
            child: Wrap(spacing: gap, runSpacing: gap, children: [
              _TagChip(
                label: ExcellentCharacter.homeworkCompleted.label,
                icon: Icons.assignment_turned_in_rounded,
                selected:
                    selectedTags.contains(ExcellentCharacter.homeworkCompleted),
                toneKey: 'success',
                onTap: () => _toggle(ExcellentCharacter.homeworkCompleted),
              ),
              _TagChip(
                label: ExcellentCharacter.helper.label,
                icon: Icons.emoji_people_rounded,
                selected: selectedTags.contains(ExcellentCharacter.helper),
                onTap: () => _toggle(ExcellentCharacter.helper),
              ),
            ]),
          ),
        Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final tag in regular)
              _TagChip(
                  label: tag.label,
                  selected: selectedTags.contains(tag),
                  onTap: () => _toggle(tag)),
            for (final tag in customTags)
              _TagChip(
                  label: tag,
                  selected: true,
                  onTap: () => onCustomTagSelected?.call(tag)),
            if (enableCustomTagAdd)
              _TagChip(
                  label: '添加自定義標籤',
                  icon: Icons.add_rounded,
                  selected: false,
                  onTap: () => _showAddCustomTagDialog(context)),
          ],
        ),
      ],
    );
  }

  /// 顯示添加自定義標籤的對話框
  void _showAddCustomTagDialog(BuildContext context) {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加自定義標籤'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: '請輸入標籤名稱',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                if (onCustomTagSelected != null) {
                  onCustomTagSelected!(textController.text.trim());
                }
                Navigator.of(context).pop();
              }
            },
            child: const Text('確定'),
          ),
        ],
      ),
    );
  }
}

/// 可點選的品格標籤膠囊。
class _TagChip extends StatelessWidget {
  const _TagChip(
      {required this.label,
      required this.selected,
      required this.onTap,
      this.icon,
      this.toneKey});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  /// 選中時的語意色；null 使用品牌暖色（surfaceTone＋brandTone 700）。
  final String? toneKey;

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    final small = ds.metric('spaceSmall');
    final foreground = !selected
        ? ds.color('secondaryText')
        : toneKey == null
            ? ds.brandTone(700)
            : ds.color(toneKey!);
    final background = !selected
        ? ds.color('secondaryBackground')
        : toneKey == null
            ? ds.surfaceTone(100)
            : ds.statusSurface(toneKey!);
    final border = !selected
        ? ds.color('border').withOpacity(.7)
        : toneKey == null
            ? ds.surfaceTone(200)
            : ds.color(toneKey!).withOpacity(.5);
    final leading = selected && icon == null ? Icons.check_rounded : icon;
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: background,
        shape: StadiumBorder(side: BorderSide(color: border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 44),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: small * 1.5),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (leading != null) ...[
                  Icon(leading, size: 18, color: foreground),
                  SizedBox(width: small * .75),
                ],
                Text(label,
                    style: TextStyle(
                        fontSize: ds.metric('labelSize'),
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

/// 簡單的優秀品格標籤顯示組件（唯讀）
class CharacterTagsDisplay extends StatelessWidget {
  /// 要顯示的標籤
  final List<ExcellentCharacter> tags;

  /// 自定義標籤
  final List<String> customTags;

  /// 是否顯示特殊標籤
  final bool showSpecialTags;

  const CharacterTagsDisplay({
    Key? key,
    required this.tags,
    this.customTags = const [],
    this.showSpecialTags = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ds = SystemTheme.of(context);
    final displayTags = showSpecialTags
        ? tags
        : tags.where((tag) => !tag.isSpecialTag).toList();

    if (displayTags.isEmpty && customTags.isEmpty) {
      return const SizedBox.shrink();
    }

    Widget chip(String label) => Container(
          padding: EdgeInsets.symmetric(
              horizontal: ds.metric('spaceSmall') * 1.25,
              vertical: ds.metric('spaceSmall') * .5),
          decoration: ShapeDecoration(
              color: ds.surfaceTone(50),
              shape:
                  StadiumBorder(side: BorderSide(color: ds.surfaceTone(200)))),
          child: Text(label,
              style: TextStyle(
                  fontSize: ds.metric('labelSize'),
                  fontWeight: FontWeight.w600,
                  color: ds.brandTone(700))),
        );

    return Wrap(
      spacing: ds.metric('spaceSmall'),
      runSpacing: ds.metric('spaceSmall'),
      children: [
        for (final tag in displayTags) chip(tag.label),
        for (final tag in customTags) chip(tag),
      ],
    );
  }
}
