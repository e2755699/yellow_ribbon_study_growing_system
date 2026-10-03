import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/student_info/student_identity_card.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_detail_page/student_profile_overview.dart';
import 'package:widgetbook_gallery/gallery_environment.dart';
import 'package:widgetbook_gallery/usecases/student_components.dart';
import 'package:widgetbook_gallery/usecases/roster_components.dart';
import 'package:widgetbook_gallery/usecases/roster_live_preview.dart';

void main() {
  testWidgets('changing enrollment mode clears unrelated field validation',
      (tester) async {
    await tester.pumpWidget(const GalleryEnvironment(
        child: MaterialApp(home: Builder(builder: enrollmentChange))));
    await tester.pumpAndSettle();
    await tester.tap(find.text('確認異動'));
    await tester.pumpAndSettle();
    expect(find.text('請選擇據點'), findsOneWidget);
    await tester.tap(find.text('轉換據點'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('核對歷史就讀期間').last);
    await tester.pumpAndSettle();
    expect(find.text('請選擇據點'), findsNothing);
    await tester.tap(find.text('確認異動'));
    await tester.pumpAndSettle();
    expect(find.text('請選擇就讀期間'), findsOneWidget);
    expect(find.text('至少 3 字，請記下核對依據'), findsOneWidget);
  });
  final cases = <String, WidgetBuilder>{
    'login action': loginAction,
    'submitting login': submittingLogin,
    'disabled login': disabledLogin,
    'privacy policy': privacyPolicy,
    'privacy action': privacyAction,
    'disabled privacy action': disabledPrivacyAction,
    'ribbon badges': ribbonBadges,
    'card': identityCard,
    'row': identityRow,
    'long card': identityLong,
    'directory': directoryReady,
    'directory loading': directoryLoading,
    'directory empty': directoryEmpty,
    'directory error': directoryError,
    'profile': profileReady,
    'profile empty': profileEmpty,
    'profile loading': profileLoading,
    'profile error': profileError,
    'long motto': profileLong,
    'section': sectionCard,
    'form': formSection,
    'avatars': avatarDefaults,
    'avatar loading': avatarLoading,
    'avatar error': avatarError,
    'journey': studentJourney,
    'Unmarked attendance': attendanceUnmarked,
    'Readonly attendance': attendanceReadonly,
    'Unassessed performance': performanceUnassessed,
    'Assessed performance': performanceAssessed,
    'Readonly performance': performanceReadonly,
    'Long performance notes': performanceLong,
    'Daily attendance roster': dailyRosterReady,
    'Daily performance roster': dailyRosterPerformance,
    'Roster loading': dailyRosterLoading,
    'Roster empty': dailyRosterEmpty,
    'Roster error': dailyRosterError,
    'Roster saved with new edits': dailyRosterPendingEdits,
    'Roster save rejected': dailyRosterRejected,
    'Roster save unconfirmed': dailyRosterUnconfirmed,
    'Roster save confirmed': dailyRosterSaved,
    'Roster saving': dailyRosterSaving,
    'Orphan history': dailyRosterOrphan,
    'Editable record text': recordTextEditable,
    'Readonly record text': recordTextReadonly,
    'New enrollment fields': enrollmentNew,
    'Unknown enrollment start': enrollmentUnknown,
    'Enrollment saving': enrollmentSaving,
    'Transfer archive and correction': enrollmentChange,
    'Final attendance rate': statisticsFinal,
    'Provisional attendance rate': statisticsPending,
    'Insufficient historical evidence': statisticsUnknown,
    'Monthly history and growth': historyReady,
    'History loading': historyLoading,
    'History error': historyError,
    'History empty': historyEmpty,
    'Live roster': liveRoster,
    'Attendance chips': attendanceChips,
    'Disabled student actions': identityDisabled,
  };
  for (final entry in cases.entries) {
    testWidgets('${entry.key} renders offline in narrow Light and Dark',
        (tester) async {
      tester.view.physicalSize = const Size(507, 768);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(GalleryEnvironment(
          child: MaterialApp(home: Builder(builder: entry.value))));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Light'));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      expect(find.text('Dark'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });
  }
  testWidgets(
      'published custom tokens reach card and profile across the journey',
      (tester) async {
    tester.view.physicalSize = const Size(1194, 834);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const GalleryEnvironment(
        child: MaterialApp(home: Builder(builder: studentJourney))));
    await tester.pumpAndSettle();
    final store =
        GalleryEnvironment.storeOf(tester.element(find.byType(ProductPreview)));
    final custom = store.active
        .duplicate(id: 'test-custom', name: '自訂驗證主題')
        .copyWith(light: {
      ...store.active.light,
      'primary': '#235F43'
    }, metrics: {
      ...store.active.metrics,
      'radiusMedium': 30,
      'titleSize': 24
    });
    store.acceptPublished(custom);
    store.select(custom.id);
    await tester.pumpAndSettle();
    final cardTheme =
        SystemTheme.of(tester.element(find.byType(StudentIdentityCard).first));
    expect(cardTheme.definition.id, custom.id);
    expect(cardTheme.metric('radiusMedium'), 30);
    expect(cardTheme.color('primary'), const Color(0xFF235F43));
    await tester.tap(find.text('林小禾'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentProfileOverview), findsOneWidget);
    final profileTheme =
        SystemTheme.of(tester.element(find.byType(StudentProfileOverview)));
    expect(profileTheme.definition.id, custom.id);
    expect(profileTheme.metric('titleSize'), 24);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.byType(StudentIdentityCard), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
