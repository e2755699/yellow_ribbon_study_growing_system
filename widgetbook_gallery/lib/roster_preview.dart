// Full-viewport entry point for visual QA. Uses the same production cases as
// Widgetbook and only synthetic fixtures; never initializes Firebase.
import 'package:flutter/material.dart';
import 'gallery_environment.dart';
import 'usecases/roster_components.dart';
import 'usecases/roster_live_preview.dart';
import 'usecases/student_components.dart';

void main() {
  final cases = <String, WidgetBuilder>{
    'save-unknown': dailyRosterUnconfirmed,
    'save-rejected': dailyRosterRejected,
    'save-confirmed': dailyRosterSaved,
    'attendance': dailyRosterReady,
    'performance': dailyRosterPerformance,
    'loading': dailyRosterLoading,
    'empty': dailyRosterEmpty,
    'error': dailyRosterError,
    'new-edits': dailyRosterPendingEdits,
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
