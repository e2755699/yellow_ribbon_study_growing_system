import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/application/design_system_editor.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/application/design_system_store.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/data/memory_design_system_repository.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/domain/theme_defaults.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/domain/theme_definition.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/design_system_dashboard.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/home_page/home_page_widget.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/home_button.dart';

class DelayedThemes extends MemoryDesignSystemRepository {
  final changes = StreamController<List<ThemeDefinition>>();
  @override
  Stream<List<ThemeDefinition>> watchThemes() => changes.stream;
  @override
  Future<void> dispose() async {
    await changes.close();
    await super.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
      'create many independent palettes, rename and reload them without changing presets',
      () async {
    final repo = MemoryDesignSystemRepository();
    final store = DesignSystemStore(repo);
    var id = 0;
    final editor =
        DesignSystemEditor(store, newId: () => 'theme_custom_${id++}');
    await editor.initialize();
    await Future<void>.delayed(Duration.zero);
    final original = store.theme('caramel').fingerprint;
    for (var i = 0; i < 20; i++) {
      expect(editor.create('自訂主題 $i'), isTrue);
      expect(editor.state.isNew, isTrue);
      expect(editor.state.dirty, isTrue);
      expect(store.contains('theme_custom_$i'), isFalse);
      expect(editor.state.draft.light, editor.state.baseline.light);
      expect(editor.state.draft.dark, editor.state.baseline.dark);
      expect(await editor.publish(), isTrue);
      expect(editor.state.draft.revision, 1);
      expect(editor.state.isNew, isFalse);
    }
    expect(store.themes.length, defaultDesignThemes().length + 20);
    expect(store.theme('caramel').fingerprint, original);
    editor.rename('森林課堂');
    expect(await editor.publish(), isTrue);
    expect(store.theme('theme_custom_19').name, '森林課堂');
    final reloaded = DesignSystemStore(repo);
    await reloaded.start();
    await Future<void>.delayed(Duration.zero);
    expect(reloaded.themes.length, store.themes.length);
    expect(reloaded.theme('theme_custom_19').name, '森林課堂');
    await editor.close();
    store.dispose();
    reloaded.dispose();
    await repo.dispose();
  });

  test('discard and readonly preview do not insert new themes', () async {
    final repo = MemoryDesignSystemRepository(writable: false);
    final store = DesignSystemStore(repo);
    final editor = DesignSystemEditor(store);
    await editor.initialize();
    await Future<void>.delayed(Duration.zero);
    editor.select('teal');
    expect(editor.create(''), isFalse);
    expect(editor.create('新的藍綠'), isTrue);
    expect(await editor.publish(), isFalse);
    expect(store.themes.length, defaultDesignThemes().length);
    editor.discard();
    expect(editor.state.draft.id, 'teal');
    expect(editor.state.dirty, isFalse);
    await editor.close();
    store.dispose();
    await repo.dispose();
  });

  test('saved custom selection survives preferences loading before remote data',
      () async {
    SharedPreferences.setMockInitialValues(
        {'home_color_theme': 'theme_remote'});
    final repo = DelayedThemes();
    final store = DesignSystemStore(repo);
    await store.start();
    expect(store.activeId, 'theme_remote');
    final custom =
        defaultDesignThemes().first.duplicate(id: 'theme_remote', name: '遠端主題');
    repo.changes.add([custom.copyWith(revision: 1)]);
    await Future<void>.delayed(Duration.zero);
    expect(store.active.id, 'theme_remote');
    store.dispose();
    await repo.dispose();
  });

  testWidgets(
      'create and publish from the dashboard, then select new theme on homepage',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(507, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final repo = MemoryDesignSystemRepository();
    final store = DesignSystemStore(repo);
    final editor = DesignSystemEditor(store, newId: () => 'theme_forest');
    GetIt.I.registerSingleton<DesignSystemStore>(store);
    await editor.initialize();
    await tester.pumpWidget(MaterialApp(
        home: BlocProvider.value(
            value: editor, child: const DesignSystemDashboard(sandbox: true))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('create-theme')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('建立草稿'));
    await tester.pumpAndSettle();
    expect(find.text('請輸入主題名稱'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('theme-name-input')), '森林課堂');
    await tester.tap(find.text('建立草稿'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('新主題 · 尚未儲存'), findsOneWidget);
    expect(store.contains('theme_forest'), isFalse);
    editor.color(false, 'primary', '#A95129');
    await tester.pump();
    await tester.ensureVisible(find.byKey(const Key('publish-theme')));
    await tester.tap(find.byKey(const Key('publish-theme')));
    await tester.pumpAndSettle();
    expect(store.theme('theme_forest').revision, 1);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.byTooltip('重新命名主題'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('重新命名主題'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('theme-name-input')), '森林教室');
    await tester.tap(find.text('套用名稱'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.ensureVisible(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('橄欖綠').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('繼續編輯'));
    await tester.pumpAndSettle();
    expect(editor.state.draft.name, '森林教室');
    expect(editor.state.draft.id, 'theme_forest');
    expect(
        tester
            .widget<DropdownButtonFormField<String>>(
                find.byType(DropdownButtonFormField<String>))
            .initialValue,
        'theme_forest');
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const Key('publish-theme')));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const MaterialApp(home: HomePageWidget()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-theme-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('森林教室'));
    await tester.pumpAndSettle();
    expect(store.activeId, 'theme_forest');
    final button = tester.widget<ElevatedButton>(
        find.byKey(const ValueKey(HomeButton.studentInfo)));
    expect(button.style!.backgroundColor!.resolve({}), const Color(0xFFA95129));
    expect(
        (await SharedPreferences.getInstance()).getString('home_color_theme'),
        'theme_forest');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await editor.close();
    GetIt.I.unregister<DesignSystemStore>();
    store.dispose();
    repo.dispose();
  });
}
