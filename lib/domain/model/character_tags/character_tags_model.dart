import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/excellent_character.dart';

/// 可定制的標籤模型，用於管理優秀品格標籤
class CharacterTagsModel {
  // 系統默認標籤（枚舉值）
  final List<ExcellentCharacter> defaultTags;
  
  // 用戶自定義標籤
  final List<String> customTags;

  const CharacterTagsModel({
    required this.defaultTags,
    this.customTags = const [],
  });

  /// 從Firebase數據創建一個CharacterTagsModel
  static CharacterTagsModel fromFirebase(Map<String, dynamic> data) {
    // 處理默認標籤
    List<ExcellentCharacter> defaultTags = [];
    if (data['defaultTags'] != null) {
      final tagsList = List<String>.from(data['defaultTags']);
      defaultTags = ExcellentCharacter.fromList(tagsList);
    } else {
      // 如果沒有保存默認標籤，則使用全部枚舉值
      defaultTags = ExcellentCharacter.values.toList();
    }

    // 處理自定義標籤
    List<String> customTags = [];
    if (data['customTags'] != null) {
      customTags = List<String>.from(data['customTags']);
    }

    return CharacterTagsModel(
      defaultTags: defaultTags,
      customTags: customTags,
    );
  }

  /// 將CharacterTagsModel轉換為Firebase數據
  Map<String, dynamic> toFirebase() {
    return {
      'defaultTags': defaultTags.map((tag) => tag.name).toList(),
      'customTags': customTags,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  /// 獲取所有可用標籤（包括默認標籤和自定義標籤）
  List<String> get allTagLabels {
    List<String> allLabels = defaultTags.map((tag) => tag.label).toList();
    allLabels.addAll(customTags);
    return allLabels;
  }

  /// 添加自定義標籤
  CharacterTagsModel addCustomTag(String tag) {
    if (tag.trim().isEmpty) return this;
    
    // 檢查是否已存在
    if (customTags.contains(tag.trim())) return this;
    
    List<String> newCustomTags = List.from(customTags);
    newCustomTags.add(tag.trim());
    
    return CharacterTagsModel(
      defaultTags: defaultTags,
      customTags: newCustomTags,
    );
  }

  /// 移除自定義標籤
  CharacterTagsModel removeCustomTag(String tag) {
    List<String> newCustomTags = List.from(customTags);
    newCustomTags.remove(tag);
    
    return CharacterTagsModel(
      defaultTags: defaultTags,
      customTags: newCustomTags,
    );
  }

  /// 啟用/禁用默認標籤
  CharacterTagsModel toggleDefaultTag(ExcellentCharacter tag) {
    List<ExcellentCharacter> newDefaultTags = List.from(defaultTags);
    
    if (newDefaultTags.contains(tag)) {
      newDefaultTags.remove(tag);
    } else {
      newDefaultTags.add(tag);
    }
    
    return CharacterTagsModel(
      defaultTags: newDefaultTags,
      customTags: customTags,
    );
  }
} 