import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/excellent_character.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/character_tags/character_tags_model.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/character_tags_repo.dart';

/// 優秀品格標籤管理的狀態
class CharacterTagsState {
  final CharacterTagsModel tagsModel;
  final bool isLoading;
  final String? errorMessage;

  CharacterTagsState({
    required this.tagsModel,
    this.isLoading = false,
    this.errorMessage,
  });

  CharacterTagsState copyWith({
    CharacterTagsModel? tagsModel,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CharacterTagsState(
      tagsModel: tagsModel ?? this.tagsModel,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// 優秀品格標籤管理的Cubit
class CharacterTagsCubit extends Cubit<CharacterTagsState> {
  final CharacterTagsRepo _tagsRepo;

  CharacterTagsCubit(this._tagsRepo)
      : super(CharacterTagsState(
          tagsModel: CharacterTagsModel(
            defaultTags: ExcellentCharacter.values.toList(),
          ),
          isLoading: true,
        )) {
    loadTags();
  }

  /// 加載標籤設置
  Future<void> loadTags() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final tags = await _tagsRepo.getCharacterTags();
      emit(CharacterTagsState(
        tagsModel: tags,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '加載標籤失敗: ${e.toString()}',
      ));
    }
  }

  /// 添加自定義標籤
  Future<void> addCustomTag(String tag) async {
    if (tag.trim().isEmpty) return;
    
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final updatedTags = await _tagsRepo.addCustomTag(tag);
      emit(state.copyWith(
        tagsModel: updatedTags,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '添加標籤失敗: ${e.toString()}',
      ));
    }
  }

  /// 移除自定義標籤
  Future<void> removeCustomTag(String tag) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final updatedTags = await _tagsRepo.removeCustomTag(tag);
      emit(state.copyWith(
        tagsModel: updatedTags,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '移除標籤失敗: ${e.toString()}',
      ));
    }
  }

  /// 切換默認標籤
  Future<void> toggleDefaultTag(ExcellentCharacter tag) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    try {
      final updatedTags = await _tagsRepo.toggleDefaultTag(tag);
      emit(state.copyWith(
        tagsModel: updatedTags,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: '更新標籤失敗: ${e.toString()}',
      ));
    }
  }
} 