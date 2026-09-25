import 'package:flutter/material.dart';
import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/nav/nav.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/application/design_system_editor.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/application/design_system_store.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/data/memory_design_system_repository.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/domain/design_system_repository.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/domain/theme_defaults.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/domain/theme_definition.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/design_system_dashboard.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';

class FailingRepository extends MemoryDesignSystemRepository {
  @override
  Future<ThemeDefinition> publish(ThemeDefinition theme,
          {required int expectedRevision}) async =>
      throw StateError('offline');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('all presets round trip, reject malformed schema and inaccessible text',
      () {
    for (final theme in defaultDesignThemes()) {
      expect(theme.validationErrors, isEmpty);
      expect(ThemeDefinition.fromJson(theme.id, theme.toJson()).fingerprint,
          theme.fingerprint);
      expect(
          () => ThemeDefinition.fromJson(
              theme.id, {...theme.toJson(), 'schemaVersion': 2}),
          throwsFormatException);
      expect(theme.withColor(false, 'primaryText', '#FDF2CB').validationErrors,
          isNotEmpty);
      expect(
          theme
              .withColor(false, 'onPrimary', theme.light['primary']!)
              .validationErrors,
          isNotEmpty);
      expect(
          theme.copyWith(metrics: {
            ...theme.metrics,
            'pressedDarken': 0.01
          }).validationErrors,
          isNotEmpty);
    }
  });

  test('repository rejects stale revisions and writes without permission',
      () async {
    final repo = MemoryDesignSystemRepository();
    addTearDown(repo.dispose);
    final seed = defaultDesignThemes().first;
    expect((await repo.publish(seed, expectedRevision: 0)).revision, 1);
    await expectLater(
        repo.publish(seed, expectedRevision: 0), throwsA(isA<ThemeConflict>()));
    final readOnly = MemoryDesignSystemRepository(writable: false);
    addTearDown(readOnly.dispose);
    await expectLater(readOnly.publish(seed, expectedRevision: 0),
        throwsA(isA<ThemePermissionDenied>()));
  });

  test(
      'draft stays private, publish broadcasts and concurrent edit preserves draft',
      () async {
    final repo = MemoryDesignSystemRepository();
    final store = DesignSystemStore(repo);
    final a = DesignSystemEditor(store), b = DesignSystemEditor(store);
    addTearDown(() async {
      await a.close();
      await b.close();
      store.dispose();
      await repo.dispose();
    });
    await a.initialize();
    await b.initialize();
    await Future<void>.delayed(Duration.zero);
    a.color(false, 'primary', '#B65E32');
    b.color(false, 'primary', '#A95129');
    expect(store.active.light['primary'], '#C86B3C');
    expect(await a.publish(), isTrue);
    expect(store.active.light['primary'], '#B65E32');
    store.acceptPublished(defaultDesignThemes().first);
    expect(store.active.revision, 1,
        reason: 'Late publish callbacks must not roll back newer snapshots');
    expect(b.state.conflict, isTrue);
    expect(b.state.draft.light['primary'], '#A95129');
    expect(await b.publish(), isFalse);
    b.discard();
    expect(b.state.draft.revision, 1);
    expect(b.state.dirty, isFalse);
  });

  test('failed save keeps the editable draft', () async {
    final repo = FailingRepository();
    final store = DesignSystemStore(repo);
    final editor = DesignSystemEditor(store);
    addTearDown(() async {
      await editor.close();
      store.dispose();
      await repo.dispose();
    });
    await editor.initialize();
    await Future<void>.delayed(Duration.zero);
    editor.color(false, 'primary', '#A95129');
    expect(await editor.publish(), isFalse);
    expect(editor.state.dirty, isTrue);
    expect(editor.state.saving, isFalse);
    expect(editor.state.message, contains('草稿仍保留'));
    expect(store.active.light['primary'], '#C86B3C');
  });

  for (final size in [
    const Size(1194, 834),
    const Size(834, 1194),
    const Size(507, 768),
    const Size(375, 667)
  ]) {
    testWidgets('dashboard edit, preview and responsive sections at $size',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repo = MemoryDesignSystemRepository();
      final store = DesignSystemStore(repo);
      final editor = DesignSystemEditor(store);
      await editor.initialize();
      await tester.pumpWidget(MaterialApp(
          home: BlocProvider.value(
              value: editor,
              child: const DesignSystemDashboard(sandbox: true))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byKey(const Key('light-primary')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('light-primary')));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.byKey(const Key('token-hex-input')), 'invalid');
      await tester.tap(find.text('套用預覽'));
      await tester.pumpAndSettle();
      expect(find.text('請輸入 # 加上 6 位十六進位色碼'), findsOneWidget);
      await tester.enterText(
          find.byKey(const Key('token-hex-input')), '#A95129');
      await tester.tap(find.text('套用預覽'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 300));
      expect(editor.state.draft.light['primary'], '#A95129');
      expect(store.active.light['primary'], '#C86B3C');
      await tester.scrollUntilVisible(
          find.byKey(const Key('publish-theme')), -400,
          scrollable: find
              .descendant(
                  of: find.byKey(const Key('design-system-scroll')),
                  matching: find.byType(Scrollable))
              .first);
      await tester.tap(find.byKey(const Key('publish-theme')));
      await tester.pumpAndSettle();
      expect(store.active.light['primary'], '#A95129');
      for (final title in ['Typography 字級', 'Layout 間距與圓角', 'Components 元件']) {
        tester
            .state<ScrollableState>(find
                .descendant(
                    of: find.byKey(const Key('design-system-scroll')),
                    matching: find.byType(Scrollable))
                .first)
            .position
            .jumpTo(0);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text(title).first);
        await tester.tap(find.text(title).first);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.scrollUntilVisible(find.byType(DesignSystemPreview), 400,
          scrollable: find
              .descendant(
                  of: find.byKey(const Key('design-system-scroll')),
                  matching: find.byType(Scrollable))
              .first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await editor.close();
      store.dispose();
      await repo.dispose();
    });
  }

  testWidgets('unauthorized editor previews but cannot publish',
      (tester) async {
    final repo = MemoryDesignSystemRepository(writable: false);
    final store = DesignSystemStore(repo);
    final editor = DesignSystemEditor(store);
    await editor.initialize();
    await tester.pumpWidget(MaterialApp(
        home: BlocProvider.value(
            value: editor, child: const DesignSystemDashboard())));
    await tester.pumpAndSettle();
    editor.color(false, 'primary', '#A95129');
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('publish-theme')))
            .onPressed,
        isNull);
    expect(await editor.publish(), isFalse);
    await tester.pumpWidget(const SizedBox());
    await editor.close();
    store.dispose();
    await repo.dispose();
  });

  test('hover and pressed use editable darkening tokens', () {
    final tokens = SystemTheme(defaultDesignThemes().first, false);
    expect(
        tokens.backgroundFor({WidgetState.hovered}).red, (0xC8 * .92).round());
    expect(
        tokens.backgroundFor({WidgetState.pressed}).red, (0xC8 * .88).round());
  });

  testWidgets('home menu opens editor; route exit protects an unsaved draft',
      (tester) async {
    final repo = MemoryDesignSystemRepository();
    final store = DesignSystemStore(repo);
    GetIt.I.registerSingleton<DesignSystemStore>(store);
    final auth = StreamController<bool>();
    final notifier =
        AppStateNotifier(signedInChanges: auth.stream, initiallySignedIn: true);
    final router = createRouter(notifier);
    await store.start();
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('home-theme-menu')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Design System'));
    await tester.pumpAndSettle();
    final editor = tester
        .element(find.byType(DesignSystemDashboard))
        .read<DesignSystemEditor>();
    editor.color(false, 'primary', '#A95129');
    await tester.pump();
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('放棄尚未儲存的變更？'), findsOneWidget);
    await tester.tap(find.text('繼續編輯'));
    await tester.pumpAndSettle();
    expect(find.byType(DesignSystemDashboard), findsOneWidget);
    expect(editor.state.dirty, isTrue);
    router.pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('放棄變更'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('home-theme-menu')), findsOneWidget);
    expect(store.active.light['primary'], '#C86B3C');
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    notifier.dispose();
    auth.close();
    GetIt.I.unregister<DesignSystemStore>();
    store.dispose();
    repo.dispose();
  });
}
