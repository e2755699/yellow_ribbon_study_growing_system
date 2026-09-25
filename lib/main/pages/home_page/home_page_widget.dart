import 'package:flutter/material.dart';
import '../../../design_system/presentation/system_theme_scope.dart';
import '../../components/privacy/privacy_policy_view.dart';
import '../../components/privacy/show_privacy_policy.dart';
import 'package:get_it/get_it.dart';
import '../../../design_system/application/design_system_store.dart';
import '../../../design_system/presentation/system_theme.dart';
import '../../../design_system/domain/theme_definition.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yellow_ribbon_study_growing_system/main/theme/home_color_theme.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/home_button.dart';
import 'package:yellow_ribbon_study_growing_system/flutter_flow/flutter_flow_theme.dart';

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  String _themeId = HomeColorTheme.defaultTheme.name;
  HomeColorTheme get _colors => HomeColorTheme.fromPreference(_themeId);
  List<ThemeDefinition> get _themes =>
      _store?.themes ??
      HomeColorTheme.values.map((theme) => theme.definition).toList();
  bool _selectedByUser = false;
  Future<void> _pendingPreference = Future.value();
  DesignSystemStore? get _store => GetIt.I.isRegistered<DesignSystemStore>()
      ? GetIt.I<DesignSystemStore>()
      : null;
  SystemTheme? get _tokens =>
      _store == null ? null : SystemTheme(_store!.theme(_themeId), false);

  @override
  void initState() {
    super.initState();
    _restoreTheme();
    _store?.addListener(_catalogChanged);
  }

  void _catalogChanged() {
    if (mounted) {
      setState(() => _themeId = _store!.active.id);
    }
  }

  @override
  void dispose() {
    _store?.removeListener(_catalogChanged);
    super.dispose();
  }

  Future<void> _restoreTheme() async {
    if (_store != null) {
      _themeId = _store!.active.id;
      return;
    }
    try {
      final preferences = await SharedPreferences.getInstance();
      if (mounted && !_selectedByUser) {
        setState(() => _themeId = HomeColorTheme.fromPreference(
                preferences.getString(HomeColorTheme.preferenceKey))
            .name);
      }
    } catch (_) {
      // A local preference failure must not prevent access to the homepage.
    }
  }

  void _selectTheme(String value) {
    _selectedByUser = true;
    setState(() => _themeId = value);
    if (_store != null) {
      _store!.select(value);
      return;
    }
    _pendingPreference = _pendingPreference.then((_) async {
      try {
        final preferences = await SharedPreferences.getInstance();
        final saved =
            await preferences.setString(HomeColorTheme.preferenceKey, value);
        if (!saved) throw StateError('Preference not saved');
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('配色已切換，這次未能記住選擇')));
        }
      }
    });
  }

  Widget _themeMenu() => Material(
        color: HomeColorTheme.controlSurface,
        borderRadius: BorderRadius.circular(22),
        child: PopupMenuButton<String>(
          key: const Key('home-theme-menu'),
          tooltip: '切換首頁主題',
          initialValue: _themeId,
          color: HomeColorTheme.controlSurface,
          icon: Icon(Icons.palette_outlined,
              color: _tokens?.color('detail') ?? _colors.detail),
          onSelected: (value) => value == '__designSystem'
              ? context.push('/designSystem')
              : _selectTheme(value),
          itemBuilder: (context) => [
            for (final colors in _themes)
              PopupMenuItem(
                value: colors.id,
                child: Row(children: [
                  Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                          color: SystemTheme(colors, false).primary,
                          shape: BoxShape.circle)),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Text(colors.name,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: HomeColorTheme.controlText))),
                  const SizedBox(width: 12),
                  if (_themeId == colors.id)
                    Icon(Icons.check,
                        size: 20,
                        color: SystemTheme(colors, false).color('detail')),
                ]),
              ),
            const PopupMenuDivider(),
            const PopupMenuItem(
                value: '__designSystem',
                child: Row(children: [
                  Icon(Icons.tune, color: HomeColorTheme.controlText),
                  SizedBox(width: 12),
                  Text('Design System',
                      style: TextStyle(color: HomeColorTheme.controlText))
                ])),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/login_bg.webp'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(builder: (context, viewport) {
            final compact = viewport.maxWidth < 680;
            final outerPadding = compact ? 20.0 : 32.0;
            return Stack(children: [
              SingleChildScrollView(
                key: const Key('home-scroll'),
                padding: EdgeInsets.all(outerPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (viewport.maxHeight - outerPadding * 2)
                        .clamp(0, double.infinity),
                  ),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 800),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _tokens?.color('secondaryBackground') ??
                            theme.onPrimary,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: LayoutBuilder(builder: (context, panel) {
                        final columns = compact ? 1 : 2;
                        final width =
                            (panel.maxWidth - (columns - 1) * 16) / columns;
                        return Wrap(spacing: 16, runSpacing: 16, children: [
                          for (final item in HomeButton.values)
                            SizedBox(
                              width: width,
                              child: ElevatedButton(
                                key: ValueKey(item),
                                style: ElevatedButton.styleFrom(
                                  foregroundColor:
                                      _tokens?.onPrimary ?? _colors.foreground,
                                  padding: EdgeInsets.all(compact ? 20 : 24),
                                  minimumSize: Size(0, compact ? 88 : 176),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(24)),
                                ).copyWith(
                                  backgroundColor:
                                      WidgetStateProperty.resolveWith(
                                          _tokens?.backgroundFor ??
                                              _colors.backgroundFor),
                                  overlayColor: const WidgetStatePropertyAll(
                                      HomeColorTheme.transparent),
                                ),
                                onPressed: () => context.push(item.routeName),
                                child: compact
                                    ? Row(children: [
                                        SvgPicture.asset(
                                            'assets/images/${item.iconName}.svg',
                                            colorFilter: ColorFilter.mode(
                                                _tokens?.onPrimary ??
                                                    _colors.foreground,
                                                BlendMode.srcIn),
                                            width: 44,
                                            height: 44),
                                        const SizedBox(width: 20),
                                        Expanded(
                                            child: Text(item.name,
                                                style: const TextStyle(
                                                    fontSize: 22,
                                                    fontWeight:
                                                        FontWeight.w700))),
                                      ])
                                    : Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            SvgPicture.asset(
                                                'assets/images/${item.iconName}.svg',
                                                colorFilter: ColorFilter.mode(
                                                    _tokens?.onPrimary ??
                                                        _colors.foreground,
                                                    BlendMode.srcIn),
                                                width: 64,
                                                height: 64),
                                            const SizedBox(height: 20),
                                            Text(item.name,
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight:
                                                        FontWeight.w700)),
                                          ]),
                              ),
                            ),
                        ]);
                      }),
                    ),
                  ),
                ),
              ),
              Positioned(
                  top: 12,
                  right: 16,
                  child: Row(children: [
                    SystemThemeScope(
                        builder: (context) => PrivacyPolicyButton(
                            onPressed: () => showPrivacyPolicy(context))),
                    _themeMenu(),
                  ]))
            ]);
          }),
        ),
      ),
    );
  }
}
