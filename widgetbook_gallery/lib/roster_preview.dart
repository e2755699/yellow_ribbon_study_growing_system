// Full-viewport entry point for visual QA. Uses the same production cases as
// Widgetbook and only synthetic fixtures; never initializes Firebase.
import 'package:flutter/material.dart';
import 'gallery_environment.dart';
import 'usecases/roster_components.dart';
import 'usecases/roster_live_preview.dart';
import 'usecases/student_components.dart';

void main() {
  final cases = <String, WidgetBuilder>{
    'attendance': dailyRosterReady,
    'performance': dailyRosterPerformance,
    'loading': dailyRosterLoading,
    'empty': dailyRosterEmpty,
    'error': dailyRosterError,
    'partial': dailyRosterPartial,
    'saving': dailyRosterSaving,
    'orphan': dailyRosterOrphan,
    'long': performanceLong,
    'enrollment': enrollmentChange,
    'history': historyReady,
    'directory': directoryReady,
    'journey': studentJourney,
    'live': liveRoster,
  };
  final builder = cases[Uri.base.queryParameters['case']] ?? liveRoster;
  runApp(
      GalleryEnvironment(child: MaterialApp(home: Builder(builder: builder))));
}
