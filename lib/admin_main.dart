import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'admin/download_pdf.dart';
import 'admin/monthly_report_demo.dart';
import 'backend/firebase/firebase_config.dart';
import 'design_system/application/design_system_store.dart';
import 'design_system/data/firebase_design_system_repository.dart';
import 'design_system/data/memory_design_system_repository.dart';
import 'design_system/presentation/components/system_page.dart';
import 'design_system/presentation/system_theme.dart';
import 'design_system/presentation/system_theme_scope.dart';
import 'domain/bloc/monthly_attendance_cubit/monthly_attendance_cubit.dart';
import 'domain/repo/firebase_roster_repository.dart';
import 'domain/repo/memory_roster_repository.dart';
import 'domain/repo/roster_repository.dart';
import 'domain/service/monthly_attendance_pdf.dart';
import 'main/components/reports/admin_login_view.dart';
import 'main/components/reports/monthly_attendance_view.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Use the bundled CJK font for the standalone web runtime's default family.
  // The regular App entrypoint and its existing typography are unaffected.
  final font = FontLoader('Roboto')
    ..addFont(rootBundle.load('assets/fonts/report/NotoSansTC-Regular.ttf'));
  await font.load();
  await initFirebase();
  final demo = Uri.base.queryParameters['demo'] == '1';
  final store = DesignSystemStore(demo
      ? MemoryDesignSystemRepository()
      : FirebaseDesignSystemRepository(
          FirebaseFirestore.instance, FirebaseAuth.instance));
  GetIt.I.registerSingleton<DesignSystemStore>(store);
  await store.start();
  runApp(_AdminApp(store: store, initialDemo: demo));
}

class _AdminApp extends StatefulWidget {
  const _AdminApp({required this.store, required this.initialDemo});
  final DesignSystemStore store;
  final bool initialDemo;
  @override
  State<_AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<_AdminApp> {
  late bool demo = widget.initialDemo;
  bool dark = false;
  void changeDemo(bool value) => setState(() => demo = value);
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: widget.store,
      builder: (context, _) => MaterialApp(
            title: '黃絲帶管理後台 · 月出席報表',
            debugShowCheckedModeBanner: false,
            theme: SystemTheme(widget.store.active, false).materialTheme(),
            darkTheme: SystemTheme(widget.store.active, true).materialTheme(),
            themeMode: dark ? ThemeMode.dark : ThemeMode.light,
            locale: const Locale('zh', 'TW'),
            supportedLocales: const [Locale('zh', 'TW')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate
            ],
            home: demo
                ? _ReportHost(
                    key: const ValueKey('demo'),
                    demo: true,
                    onTheme: () => setState(() => dark = !dark),
                    onExit: () => changeDemo(false))
                : StreamBuilder<User?>(
                    stream: FirebaseAuth.instance.authStateChanges(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Scaffold(
                            body: Center(child: CircularProgressIndicator()));
                      }
                      if (snapshot.data == null) {
                        return AdminLoginView(
                            onDemo: () => changeDemo(true),
                            onLogin: (email, password) async {
                              try {
                                await FirebaseAuth.instance
                                    .signInWithEmailAndPassword(
                                        email: email, password: password)
                                    .timeout(const Duration(seconds: 60));
                                return null;
                              } on FirebaseAuthException catch (error) {
                                return switch (error.code) {
                                  'invalid-credential' ||
                                  'wrong-password' ||
                                  'user-not-found' =>
                                    '帳號或密碼不正確。',
                                  'too-many-requests' => '登入嘗試次數過多，請稍後重試。',
                                  'network-request-failed' => '網路連線失敗，請檢查連線。',
                                  _ => '無法登入，請確認帳號與連線。'
                                };
                              } catch (_) {
                                return '登入尚未完成，請稍後重試。';
                              }
                            });
                      }
                      return _ReportHost(
                          key: ValueKey(snapshot.data!.uid),
                          demo: false,
                          onTheme: () => setState(() => dark = !dark),
                          onExit: () => FirebaseAuth.instance.signOut());
                    }),
          ));
}

class _ReportHost extends StatefulWidget {
  const _ReportHost(
      {super.key,
      required this.demo,
      required this.onExit,
      required this.onTheme});
  final bool demo;
  final VoidCallback onExit, onTheme;
  @override
  State<_ReportHost> createState() => _ReportHostState();
}

class _ReportHostState extends State<_ReportHost> {
  final _scaffold = GlobalKey<ScaffoldState>();
  late final RosterRepository _repository = widget.demo
      ? monthlyReportDemoRepository()
      : FirebaseRosterRepository(
          FirebaseFirestore.instance, FirebaseAuth.instance);
  @override
  void dispose() {
    if (_repository is FirebaseRosterRepository) {
      (_repository as FirebaseRosterRepository).dispose();
    } else if (_repository is MemoryRosterRepository) {
      (_repository as MemoryRosterRepository).events.close();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
      create: (_) => MonthlyAttendanceCubit(_repository,
          initialMonth: widget.demo ? DateTime(2026, 10) : null)
        ..start(),
      child: SystemThemeScope(
          builder: (context) => SystemPage(
              title: '黃絲帶管理後台',
              scaffoldKey: _scaffold,
              showBackButton: false,
              child:
                  BlocConsumer<MonthlyAttendanceCubit, MonthlyAttendanceState>(
                listenWhen: (previous, current) =>
                    previous.exportError != current.exportError &&
                    current.exportError != null,
                listener: (context, state) => ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(state.exportError!))),
                builder: (context, state) {
                  final cubit = context.read<MonthlyAttendanceCubit>();
                  return MonthlyAttendanceView(
                      state: state,
                      demo: widget.demo,
                      onMonth: cubit.selectMonth,
                      onSite: cubit.selectSite,
                      onRetry: cubit.retry,
                      onExit: widget.onExit,
                      onTheme: widget.onTheme,
                      onDownload: () => cubit.download(
                          (report) async => MonthlyAttendancePdf.build(
                              report,
                              await rootBundle.load(
                                  'assets/fonts/report/NotoSansTC-Regular.ttf')),
                          downloadPdf));
                },
              ))));
}
