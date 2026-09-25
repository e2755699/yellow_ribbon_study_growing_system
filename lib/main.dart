import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'design_system/application/design_system_store.dart';
import 'design_system/data/firebase_design_system_repository.dart';
import 'design_system/domain/design_system_repository.dart';
import 'design_system/presentation/system_theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_attendance_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_performance_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'backend/firebase/firebase_config.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/internationalization.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The native iOS target is iPad-only. Match its landscape-only Info.plist.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  await initFirebase();

  await FlutterFlowTheme.initialize();

  _injectDependency();
  final appState = FFAppState(); // Initialize FFAppState
  await appState.initializePersistedState();

  if (!kIsWeb) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  }

  runApp(ChangeNotifierProvider(
    create: (context) => appState,
    child: MyApp(),
  ));
}

void _injectDependency() {
  GetIt.I.registerLazySingleton<DesignSystemRepository>(() =>
      FirebaseDesignSystemRepository(
          FirebaseFirestore.instance, FirebaseAuth.instance));
  GetIt.I.registerSingleton<DesignSystemStore>(
      DesignSystemStore(GetIt.I<DesignSystemRepository>())..start());
  GetIt.instance.registerLazySingleton<StudentsRepo>(
    () => StudentsRepo(),
  );
  GetIt.instance.registerLazySingleton<DailyAttendanceRepo>(
    () => DailyAttendanceRepo(),
  );
  GetIt.instance.registerLazySingleton<DailyPerformanceRepo>(
    () => DailyPerformanceRepo(GetIt.instance<StudentsRepo>()),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;

  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
  }

  void setLocale(String language) {
    safeSetState(() => _locale = createLocale(language));
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(2360, 1640),
      child: MaterialApp.router(
        title: 'YellowRibbonStudyGrowingSystem',
        builder: (context, child) {
          if (!GetIt.I.isRegistered<DesignSystemStore>()) return child!;
          final store = GetIt.I<DesignSystemStore>();
          return AnimatedBuilder(
              animation: store,
              builder: (context, _) {
                if (!store.hasPublishedActive) return child!;
                return Theme(
                    data: SystemTheme(store.active,
                            Theme.of(context).brightness == Brightness.dark)
                        .materialTheme(),
                    child: child!);
              });
        },
        localizationsDelegates: const [
          FFLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          FallbackMaterialLocalizationDelegate(),
          FallbackCupertinoLocalizationDelegate(),
        ],
        locale: _locale,
        supportedLocales: const [
          Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
          Locale('en'),
        ],
        theme: ThemeData(
          brightness: Brightness.light,
          checkboxTheme: CheckboxThemeData(
            fillColor: WidgetStateProperty.resolveWith<Color>(
                (Set<WidgetState> states) {
              if (states.contains(WidgetState.pressed)) {
                return FlutterFlowTheme.of(context)
                    .primary
                    .withOpacity(0.5); // 按下時的顏色
              }
              if (states.contains(WidgetState.disabled)) {
                return FlutterFlowTheme.of(context)
                    .primary
                    .withOpacity(0.4); // 按下時的顏色
              }
              return FlutterFlowTheme.of(context).primary; // 默認顏色
            }),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color>(
                  (Set<WidgetState> states) {
                if (states.contains(WidgetState.pressed)) {
                  return FlutterFlowTheme.of(context)
                      .primary
                      .withOpacity(0.5); // 按下時的顏色
                }
                if (states.contains(WidgetState.disabled)) {
                  return FlutterFlowTheme.of(context)
                      .primary
                      .withOpacity(0.4); // 按下時的顏色
                }

                return FlutterFlowTheme.of(context).primary; // 默認顏色
              }),
              foregroundColor: WidgetStateProperty.all(Colors.white),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            labelStyle: TextStyle(
              color: FlutterFlowTheme.of(context).primaryText,
            ),
          ),
          disabledColor: FlutterFlowTheme.of(context).primaryText,
          useMaterial3: false,
        ),
        darkTheme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: false,
        ),
        themeMode: _themeMode,
        routerConfig: _router,
      ),
    );
  }
}
