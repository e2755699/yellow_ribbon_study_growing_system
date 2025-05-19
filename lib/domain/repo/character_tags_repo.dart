import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/excellent_character.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/character_tags/character_tags_model.dart';

class CharacterTagsRepo {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'settings';
  final String _documentId = 'character_tags';

  /// 獲取優秀品格標籤
  Future<CharacterTagsModel> getCharacterTags() async {
    try {
      final docSnapshot = await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .get();

      if (docSnapshot.exists) {
        return CharacterTagsModel.fromFirebase(docSnapshot.data()!);
      } else {
        // 如果不存在文檔，創建一個默認的標籤集，並保存到Firebase
        final defaultTagsModel = CharacterTagsModel(
          defaultTags: ExcellentCharacter.values.toList(),
        );

        await _firestore
            .collection(_collectionName)
            .doc(_documentId)
            .set(defaultTagsModel.toFirebase());

        return defaultTagsModel;
      }
    } catch (e) {
      print('Error getting character tags: $e');
      // 出錯時返回默認標籤
      return CharacterTagsModel(
        defaultTags: ExcellentCharacter.values.toList(),
      );
    }
  }

  /// 保存更新的標籤設置
  Future<void> saveCharacterTags(CharacterTagsModel tags) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(_documentId)
          .set(tags.toFirebase());
    } catch (e) {
      print('Error saving character tags: $e');
      throw Exception('保存標籤失敗，請重試');
    }
  }

  /// 添加自定義標籤
  Future<CharacterTagsModel> addCustomTag(String tag) async {
    final currentTags = await getCharacterTags();
    final updatedTags = currentTags.addCustomTag(tag);
    await saveCharacterTags(updatedTags);
    return updatedTags;
  }

  /// 移除自定義標籤
  Future<CharacterTagsModel> removeCustomTag(String tag) async {
    final currentTags = await getCharacterTags();
    final updatedTags = currentTags.removeCustomTag(tag);
    await saveCharacterTags(updatedTags);
    return updatedTags;
  }

  /// 啟用/禁用默認標籤
  Future<CharacterTagsModel> toggleDefaultTag(ExcellentCharacter tag) async {
    final currentTags = await getCharacterTags();
    final updatedTags = currentTags.toggleDefaultTag(tag);
    await saveCharacterTags(updatedTags);
    return updatedTags;
  }
} 