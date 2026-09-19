import 'dart:async';
import '../../design_system/application/design_system_editor.dart';
import '../../design_system/application/design_system_store.dart';
import '../../design_system/presentation/design_system_dashboard.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_activity_cubit/student_activity_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/daily_performance_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_cubit/student_cubit.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/daily_attendance_page/daily_attendance_page_widget.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/growing_report_page/growing_report_page_widget.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/login_page/login_page_widget.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_detail_page/student_detail_page_widget.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_history_performance_page/student_history_performance_page_widget.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_info_page/student_info_page_widget.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/daily_performance_page/daily_performance_page_widget.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_performance_page/student_performance_page_widget.dart';
import '/backend/backend.dart';

import '/index.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_state.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';

export 'package:go_router/go_router.dart';
export 'serialization_util.dart';

const kTransitionInfoKey = '__transition_info__';

class AppStateNotifier extends ChangeNotifier {
  AppStateNotifier(
      {required Stream<bool> signedInChanges, bool initiallySignedIn = false})
      : _signedIn = initiallySignedIn {
    _authSubscription = signedInChanges.listen((signedIn) {
      _signedIn = signedIn;
      notifyListeners();
    });
  }

  late final StreamSubscription<bool> _authSubscription;
  bool _signedIn;
  bool get signedIn => _signedIn;

  static AppStateNotifier? _instance;

  static AppStateNotifier get instance => _instance ??= AppStateNotifier(
        initiallySignedIn: FirebaseAuth.instance.currentUser != null,
        signedInChanges: FirebaseAuth.instance
            .authStateChanges()
            .map((user) => user != null),
      );

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  bool showSplashImage = true;

  void stopShowingSplashImage() {
    showSplashImage = false;
    notifyListeners();
  }
}

GoRouter createRouter(AppStateNotifier appStateNotifier) {
  final designSystemKey = GlobalKey<DesignSystemDashboardState>();
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: appStateNotifier,
    redirect: (context, state) {
      final atLogin = state.uri.path == '/';
      if (!appStateNotifier.signedIn) return atLogin ? null : '/';
      if (state.uri.path == '/buttonShowcase') return YbRoute.home.routeName;
      return atLogin ? YbRoute.home.routeName : null;
    },
    errorBuilder: (context, state) => const LoginPageWidget(),
    routes: [
      FFRoute(
        name: 'designSystem',
        path: '/designSystem',
        onExit: (context) async =>
            await designSystemKey.currentState?.confirmExit() ?? true,
        builder: (context, _) => BlocProvider(
          create: (_) =>
              DesignSystemEditor(GetIt.I<DesignSystemStore>())..initialize(),
          child: DesignSystemDashboard(
              key: designSystemKey,
              onExit: () =>
                  context.canPop() ? context.pop() : context.go('/home')),
        ),
      ),
      FFRoute(
        name: '_initialize',
        path: '/',
        builder: (context, _) => const LoginPageWidget(),
      ),
      FFRoute(
        name: YbRoute.home.name,
        path: YbRoute.home.routeName,
        builder: (context, _) => const HomePageWidget(),
      ),
      FFRoute(
        name: YbRoute.studentInfo.name,
        path: YbRoute.studentInfo.routeName,
        builder: (context, _) => BlocProvider(
          create: (_) => StudentsCubit(StudentsState([]))..load(),
          child: const StudentInfoPageWidget(),
        ),
      ),
      FFRoute(
        name: YbRoute.dailyAttendance.name,
        path: YbRoute.dailyAttendance.routeName,
        builder: (context, params) => const DailyAttendancePageWidget(),
      ),
      FFRoute(
        name: YbRoute.dailyPerformance.name,
        path: YbRoute.dailyPerformance.routeName,
        builder: (context, params) => const DailyPerformancePageWidget(),
      ),
      FFRoute(
        name: YbRoute.studentPerformanceDetail.name,
        path: "${YbRoute.studentPerformanceDetail.routeName}/:sid",
        builder: (context, fFParameters) {
          var params = fFParameters.state.pathParameters;
          var sid = params['sid'] ?? "";
          return StudentPerformancePageWidget.fromRouteParams(
            sid,
          );
        },
      ),
      FFRoute(
        name: YbRoute.studentDetail.name,
        path: "${YbRoute.studentDetail.routeName}/:operate/:sid",
        builder: (context, fFParameters) {
          var params = fFParameters.state.pathParameters;
          var operate =
              Operate.values.where((o) => o.name == params["operate"]).first;
          var sid = params['sid'] ?? "";

          return BlocProvider<StudentDetailCubit>(
            create: (context) {
              final cubit = StudentDetailCubit(StudentDetailInitial(
                  operate: operate, detail: StudentDetail.empty()));

              if (sid.isNotEmpty && operate != Operate.create) {
                cubit.loadStudentById(sid, operate: operate);
              } else if (operate == Operate.create) {
                cubit.createStudentDetail(operate: Operate.create);
              }
              return cubit;
            },
            child: BlocProvider(
              create: (_) => StudentActivityCubit(() =>
                  operate == Operate.create
                      ? Future.value([])
                      : GetIt.I<DailyPerformanceRepo>().loadByStudentId(sid))
                ..load(),
              child: const StudentDetailPageWidget(),
            ),
          );
        },
      ),
      FFRoute(
        name: YbRoute.studentHistoryPerformance.name,
        path: "${YbRoute.studentHistoryPerformance.routeName}/:studentId",
        builder: (context, fFParameters) {
          var params = fFParameters.state.pathParameters;
          return StudentHistoryPerformancePageWidget.fromParams(params);
        },
      ),
      FFRoute(
        name: YbRoute.growingReport.name,
        path: YbRoute.growingReport.routeName,
        builder: (context, _) => const GrowingReportPageWidget(),
      ),
    ].map((r) => r.toRoute(appStateNotifier)).toList(),
  );
}

enum YbRoute {
  home("/home"),
  dailyAttendance("/dailyAttendance"),
  studentInfo("/studentInfo"),
  studentDetail("/studentDetail"),
  dailyPerformance("/dailyPerformance"),
  studentPerformance("/studentPerformance"),
  studentPerformanceDetail("/studentPerformanceDetail"),
  studentHistoryPerformance("/studentHistoryPerformance"),
  growingReport("/growingReport");

  final String routeName;

  const YbRoute(this.routeName);
}

extension NavParamExtensions on Map<String, String?> {
  Map<String, String> get withoutNulls => Map.fromEntries(
        entries
            .where((e) => e.value != null)
            .map((e) => MapEntry(e.key, e.value!)),
      );
}

extension NavigationExtensions on BuildContext {
  void safePop() {
    // If there is only one route on the stack, navigate to the initial
    // page instead of popping.
    if (canPop()) {
      pop();
    } else {
      go('/');
    }
  }
}

extension _GoRouterStateExtensions on GoRouterState {
  Map<String, dynamic> get extraMap =>
      extra != null ? extra as Map<String, dynamic> : {};

  Map<String, dynamic> get allParams => <String, dynamic>{}
    ..addAll(pathParameters)
    ..addAll(uri.queryParameters)
    ..addAll(extraMap);

  TransitionInfo get transitionInfo => extraMap.containsKey(kTransitionInfoKey)
      ? extraMap[kTransitionInfoKey] as TransitionInfo
      : TransitionInfo.appDefault();
}

class FFParameters {
  FFParameters(this.state, [this.asyncParams = const {}]);

  final GoRouterState state;
  final Map<String, Future<dynamic> Function(String)> asyncParams;

  Map<String, dynamic> futureParamValues = {};

  // Parameters are empty if the params map is empty or if the only parameter
  // present is the special extra parameter reserved for the transition info.
  bool get isEmpty =>
      state.allParams.isEmpty ||
      (state.allParams.length == 1 &&
          state.extraMap.containsKey(kTransitionInfoKey));

  bool isAsyncParam(MapEntry<String, dynamic> param) =>
      asyncParams.containsKey(param.key) && param.value is String;

  bool get hasFutures => state.allParams.entries.any(isAsyncParam);

  Future<bool> completeFutures() => Future.wait(
        state.allParams.entries.where(isAsyncParam).map(
          (param) async {
            final doc = await asyncParams[param.key]!(param.value)
                .onError((_, __) => null);
            if (doc != null) {
              futureParamValues[param.key] = doc;
              return true;
            }
            return false;
          },
        ),
      ).onError((_, __) => [false]).then((v) => v.every((e) => e));

  dynamic getParam<T>(
    String paramName,
    ParamType type, {
    bool isList = false,
    List<String>? collectionNamePath,
    StructBuilder<T>? structBuilder,
  }) {
    if (futureParamValues.containsKey(paramName)) {
      return futureParamValues[paramName];
    }
    if (!state.allParams.containsKey(paramName)) {
      return null;
    }
    final param = state.allParams[paramName];
    // Got parameter from `extras`, so just directly return it.
    if (param is! String) {
      return param;
    }
    // Return serialized value.
    return deserializeParam<T>(
      param,
      type,
      isList,
      collectionNamePath: collectionNamePath,
      structBuilder: structBuilder,
    );
  }
}

class FFRoute {
  const FFRoute({
    required this.name,
    required this.path,
    required this.builder,
    this.requireAuth = false,
    this.asyncParams = const {},
    this.routes = const [],
    this.onExit,
  });

  final String name;
  final String path;
  final bool requireAuth;
  final Map<String, Future<dynamic> Function(String)> asyncParams;
  final Widget Function(BuildContext, FFParameters) builder;
  final List<GoRoute> routes;
  final FutureOr<bool> Function(BuildContext)? onExit;

  GoRoute toRoute(AppStateNotifier appStateNotifier) => GoRoute(
        name: name,
        path: path,
        onExit: onExit,
        pageBuilder: (context, state) {
          fixStatusBarOniOS16AndBelow(context);
          final ffParams = FFParameters(state, asyncParams);
          final page = ffParams.hasFutures
              ? FutureBuilder(
                  future: ffParams.completeFutures(),
                  builder: (context, _) => builder(context, ffParams),
                )
              : builder(context, ffParams);
          final child = page;

          final transitionInfo = state.transitionInfo;
          return transitionInfo.hasTransition
              ? CustomTransitionPage(
                  key: state.pageKey,
                  child: child,
                  transitionDuration: transitionInfo.duration,
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          PageTransition(
                    type: transitionInfo.transitionType,
                    duration: transitionInfo.duration,
                    reverseDuration: transitionInfo.duration,
                    alignment: transitionInfo.alignment,
                    child: child,
                  ).buildTransitions(
                    context,
                    animation,
                    secondaryAnimation,
                    child,
                  ),
                )
              : MaterialPage(key: state.pageKey, child: child);
        },
        routes: routes,
      );
}

class TransitionInfo {
  const TransitionInfo({
    required this.hasTransition,
    this.transitionType = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.alignment,
  });

  final bool hasTransition;
  final PageTransitionType transitionType;
  final Duration duration;
  final Alignment? alignment;

  static TransitionInfo appDefault() =>
      const TransitionInfo(hasTransition: false);
}

class RootPageContext {
  const RootPageContext(this.isRootPage, [this.errorRoute]);

  final bool isRootPage;
  final String? errorRoute;

  static bool isInactiveRootPage(BuildContext context) {
    final rootPageContext = context.read<RootPageContext?>();
    final isRootPage = rootPageContext?.isRootPage ?? false;
    final location = GoRouterState.of(context).uri.toString();
    return isRootPage &&
        location != '/' &&
        location != rootPageContext?.errorRoute;
  }

  static Widget wrap(Widget child, {String? errorRoute}) => Provider.value(
        value: RootPageContext(true, errorRoute),
        child: child,
      );
}

extension GoRouterLocationExtension on GoRouter {
  String getCurrentLocation() {
    final RouteMatch lastMatch = routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }
}
