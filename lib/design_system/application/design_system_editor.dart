import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../domain/design_system_repository.dart';
import '../domain/theme_definition.dart';
import 'design_system_store.dart';

class DesignSystemEditorState {
  const DesignSystemEditorState(
      {required this.draft,
      required this.baseline,
      this.canPublish = false,
      this.saving = false,
      this.conflict = false,
      this.message});
  final ThemeDefinition draft;
  final ThemeDefinition baseline;
  final bool canPublish;
  final bool saving;
  final bool conflict;
  final String? message;
  bool get isNew => draft.id != baseline.id;
  bool get dirty => isNew || draft.fingerprint != baseline.fingerprint;
}

class DesignSystemEditor extends Cubit<DesignSystemEditorState> {
  DesignSystemEditor(this.store, {String Function()? newId})
      : _newId = newId ?? (() => 'theme_${const Uuid().v4()}'),
        super(DesignSystemEditorState(
            draft: store.active, baseline: store.active)) {
    store.addListener(_catalogChanged);
  }
  final DesignSystemStore store;
  final String Function() _newId;
  List<ThemeDefinition> get themes => [
        ...store.themes,
        if (state.isNew && !store.contains(state.draft.id)) state.draft,
      ];
  Future<void> initialize() async {
    await store.start();
    try {
      final allowed = await store.repository.canPublish();
      if (!isClosed) _emit(canPublish: allowed);
    } catch (_) {
      if (!isClosed) _emit(message: '無法確認編輯權限；仍可在此預覽。');
    }
  }

  void _emit(
          {ThemeDefinition? draft,
          ThemeDefinition? baseline,
          bool? canPublish,
          bool? saving,
          bool? conflict,
          String? message}) =>
      emit(DesignSystemEditorState(
          draft: draft ?? state.draft,
          baseline: baseline ?? state.baseline,
          canPublish: canPublish ?? state.canPublish,
          saving: saving ?? state.saving,
          conflict: conflict ?? state.conflict,
          message: message));

  void _catalogChanged() {
    if (isClosed) return;
    if (state.isNew && !store.contains(state.draft.id)) {
      _emit();
      return;
    }
    final incoming = store.theme(state.draft.id);
    if (state.saving) return;
    if (state.dirty) {
      _emit(
          conflict:
              state.isNew || incoming.revision != state.baseline.revision);
    } else {
      _emit(draft: incoming, baseline: incoming, conflict: false);
    }
  }

  bool select(String id) {
    if (state.dirty || state.saving || !store.contains(id)) return false;
    final theme = store.theme(id);
    _emit(draft: theme, baseline: theme, conflict: false);
    return true;
  }

  void discard() {
    if (state.saving) return;
    final theme = store.theme(state.isNew ? state.baseline.id : state.draft.id);
    _emit(draft: theme, baseline: theme, conflict: false);
  }

  /// Clone a saved theme into an isolated draft. No backend write until publish.
  bool create(String name) {
    if (state.dirty ||
        state.saving ||
        name.trim().isEmpty ||
        name.trim().length > 40) return false;
    final id = _newId();
    if (!ThemeDefinition.validId(id) || store.contains(id)) return false;
    _emit(
        draft: state.draft.duplicate(id: id, name: name),
        baseline: state.draft,
        conflict: false);
    return true;
  }

  void rename(String name) {
    if (!state.saving && name.trim().isNotEmpty && name.trim().length <= 40) {
      _emit(draft: state.draft.copyWith(name: name.trim()));
    }
  }

  void color(bool dark, String key, String value) {
    if (!state.saving) _emit(draft: state.draft.withColor(dark, key, value));
  }

  void metric(String key, double value) {
    if (state.saving || !ThemeDefinition.metricRanges.containsKey(key)) return;
    _emit(
        draft: state.draft
            .copyWith(metrics: {...state.draft.metrics, key: value}));
  }

  Future<bool> publish() async {
    if (!state.canPublish || state.saving || !store.loaded || state.conflict) {
      return false;
    }
    if (!state.dirty) return true;
    final errors = state.draft.validationErrors;
    if (errors.isNotEmpty) {
      _emit(message: errors.join('；'));
      return false;
    }
    final draft = state.draft;
    final revision = state.isNew ? 0 : state.baseline.revision;
    _emit(saving: true);
    try {
      final saved =
          await store.repository.publish(draft, expectedRevision: revision);
      store.acceptPublished(saved);
      final latest = store.theme(saved.id);
      if (!isClosed) {
        _emit(
            draft: latest,
            baseline: latest,
            saving: false,
            conflict: false,
            message:
                latest.revision > saved.revision ? '已儲存，並同步較新的雲端版本' : '已儲存主題');
      }
      return true;
    } on ThemeConflict {
      if (!isClosed) {
        _emit(
            saving: false, conflict: true, message: '其他人已更新此主題；草稿仍保留，請先重新載入。');
      }
    } on ThemePermissionDenied {
      if (!isClosed) {
        _emit(saving: false, canPublish: false, message: '沒有共用主題儲存權限，草稿仍保留。');
      }
    } catch (_) {
      if (!isClosed) _emit(saving: false, message: '儲存失敗，草稿仍保留，請檢查連線與權限後重試。');
    }
    return false;
  }

  @override
  Future<void> close() {
    store.removeListener(_catalogChanged);
    return super.close();
  }
}
