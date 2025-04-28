import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/excellent_character.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';

/// 優秀品格標籤選擇器組件
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

  const CharacterTagSelector({
    Key? key,
    required this.selectedTags,
    required this.availableTags,
    this.customTags = const [],
    required this.onTagsChanged,
    this.onCustomTagSelected,
    this.enableCustomTagAdd = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 標籤流式布局
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // 顯示所有可用系統標籤
            ...availableTags.map((tag) => _buildTag(context, tag)),
            
            // 顯示所有自定義標籤
            ...customTags.map((tag) => _buildCustomTag(context, tag)),
            
            // 添加自定義標籤的按鈕
            if (enableCustomTagAdd)
              _buildAddCustomTagButton(context),
          ],
        ),
      ],
    );
  }
  
  /// 構建系統標籤
  Widget _buildTag(BuildContext context, ExcellentCharacter tag) {
    final isSelected = selectedTags.contains(tag);
    
    return GestureDetector(
      onTap: () {
        final updatedTags = List<ExcellentCharacter>.from(selectedTags);
        if (isSelected) {
          updatedTags.remove(tag);
        } else {
          updatedTags.add(tag);
        }
        onTagsChanged(updatedTags);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? FlutterFlowTheme.of(context).primary.withOpacity(0.2)
              : FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? FlutterFlowTheme.of(context).primary
                : FlutterFlowTheme.of(context).borderPrimary,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(
                  Icons.check_circle,
                  size: 16,
                  color: FlutterFlowTheme.of(context).primary,
                ),
              ),
            Text(
              tag.label,
              style: FlutterFlowTheme.of(context).bodySmall.copyWith(
                color: isSelected
                    ? FlutterFlowTheme.of(context).primary
                    : FlutterFlowTheme.of(context).secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 構建自定義標籤
  Widget _buildCustomTag(BuildContext context, String tag) {
    return GestureDetector(
      onTap: () {
        if (onCustomTagSelected != null) {
          onCustomTagSelected!(tag);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).accent1.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: FlutterFlowTheme.of(context).accent1,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              tag,
              style: FlutterFlowTheme.of(context).bodySmall.copyWith(
                color: FlutterFlowTheme.of(context).accent1,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 構建添加自定義標籤的按鈕
  Widget _buildAddCustomTagButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _showAddCustomTagDialog(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: FlutterFlowTheme.of(context).primary.withOpacity(0.5),
            width: 1,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add,
              size: 16,
              color: FlutterFlowTheme.of(context).primary,
            ),
            const SizedBox(width: 4),
            Text(
              '添加自定義標籤',
              style: FlutterFlowTheme.of(context).bodySmall.copyWith(
                color: FlutterFlowTheme.of(context).primary,
              ),
            ),
          ],
        ),
      ),
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
          TextButton(
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

/// 簡單的優秀品格標籤顯示組件
class CharacterTagsDisplay extends StatelessWidget {
  /// 要顯示的標籤
  final List<ExcellentCharacter> tags;
  
  /// 自定義標籤
  final List<String> customTags;

  const CharacterTagsDisplay({
    Key? key,
    required this.tags,
    this.customTags = const [],
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty && customTags.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...tags.map((tag) => _buildTagChip(context, tag.label)),
        ...customTags.map((tag) => _buildTagChip(context, tag, isCustom: true)),
      ],
    );
  }
  
  Widget _buildTagChip(BuildContext context, String label, {bool isCustom = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isCustom
            ? FlutterFlowTheme.of(context).accent1.withOpacity(0.1)
            : FlutterFlowTheme.of(context).primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: FlutterFlowTheme.of(context).bodySmall.copyWith(
          color: isCustom
              ? FlutterFlowTheme.of(context).accent1
              : FlutterFlowTheme.of(context).primary,
        ),
      ),
    );
  }
} 