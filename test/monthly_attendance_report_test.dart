import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:yellow_ribbon_study_growing_system/admin/monthly_report_demo.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/domain/theme_defaults.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/monthly_attendance_cubit/monthly_attendance_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/roster/monthly_attendance_report.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/roster/roster_models.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/memory_roster_repository.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/roster_repository.dart';
import 'package:yellow_ribbon_study_growing_system/domain/service/monthly_attendance_service.dart';
import 'package:yellow_ribbon_study_growing_system/domain/service/monthly_attendance_pdf.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/reports/monthly_attendance_view.dart';
import 'package:yellow_ribbon_study_growing_system/main/components/reports/admin_login_view.dart';

BusinessDate day(int d) =>
    BusinessDate('2026-10-${d.toString().padLeft(2, '0')}');
const site = ClassSite('a', '合成測試據點');
Enrollment period(String sid, {int start = 1, int end = 31}) =>
    Enrollment('enroll-$sid',
        studentId: sid,
        locationId: 'a',
        startDate: day(start),
        endDateExclusive: day(end));
DailyRecord record(int d, String status,
        {String sid = 'one',
        String reason = '',
        String provenance = 'confirmed',
        List<String> confirmed = const []}) =>
    DailyRecord('attendance',
        studentId: sid,
        locationId: 'a',
        date: day(d),
        values: {'status': status, 'leaveReason': reason},
        nameSnapshot: '合成歷史學生',
        provenance: provenance,
        confirmedFields: confirmed);
MonthlyAttendanceReport report(
        {List<DailyRecord> records = const [],
        List<Enrollment>? enrollments,
        List<ClassSession>? sessions}) =>
    MonthlyAttendanceService.build(
        month: DateTime(2026, 10),
        site: site,
        students: const [StudentSummary('one', '合成小禾')],
        enrollments: enrollments ?? [period('one')],
        records: records,
        sessions: sessions ??
            List.generate(
                10, (i) => ClassSession('a', day(i + 1), SessionStatus.held)));
Future<void> tick() async {
  for (var i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'month scope excludes adjacent months and preserves more than 100 records',
      () async {
    final repo = monthlyReportDemoRepository(count: 32);
    final snapshot = await MonthlyAttendanceService(repo)
        .watch(DateTime(2026, 10), repo.sites.first)
        .first;
    expect(snapshot.recordCount, 703);
    expect(snapshot.rows.length, 32);
    final historical =
        await repo.watchRecords('attendance', repo.sites.first.id).first;
    expect(historical.data.length, 100);
    final empty = await MonthlyAttendanceService(repo)
        .watch(DateTime(2026, 11), repo.sites.first)
        .first;
    expect(empty.rows, isEmpty);
    expect(empty.recordCount, 0);
    await repo.events.close();
  });
  test(
      'missing is not absent, cancelled and unknown sessions do not inflate expected',
      () {
    final r = report(records: [
      record(1, 'attend'),
      record(2, 'absent'),
      record(3, 'attend')
    ], sessions: [
      ClassSession('a', day(1), SessionStatus.held),
      ClassSession('a', day(2), SessionStatus.cancelled),
      ClassSession('a', day(4), SessionStatus.held)
    ]).rows.single;
    expect(r.expected, 2);
    expect(r.present, 1);
    expect(r.absent, 0);
    expect(r.missing, 1);
    expect(r.pending, 2);
    expect(r.days[1].symbol, '×＊');
    expect(r.days[2].symbol, '○＊');
    expect(r.days[3].symbol, '?');
    expect(r.rateLabel, '100%*');
  });
  test('effective periods retain historical students and flag orphan records',
      () {
    final r = report(records: [
      record(1, 'attend'),
      record(3, 'attend'),
      record(9, 'attend', sid: 'orphan')
    ], enrollments: [
      period('one', start: 2, end: 4)
    ]);
    expect(r.rows.length, 2);
    final one = r.rows.firstWhere((x) => x.studentId == 'one');
    expect(one.expected, 2);
    expect(one.present, 1);
    expect(one.pending, 1);
    expect(r.rows.firstWhere((x) => x.studentId == 'orphan').name, '合成歷史學生');
  });
  test('empty same-day period is not a monthly roster member', () {
    expect(
        report(enrollments: [period('one', start: 2, end: 2)]).rows, isEmpty);
  });
  test('status classification keeps unidentified leave and school bus separate',
      () {
    final r = report(records: [
      record(1, 'attend'),
      record(2, 'late'),
      record(3, 'earlyLeave'),
      record(4, 'leave', reason: '病假'),
      record(5, 'leave', reason: '事假'),
      record(6, 'leave', reason: '回診'),
      record(7, 'leave'),
      record(8, 'busAbsent'),
      record(9, 'absent')
    ]).rows.single;
    expect(r.present, 3);
    expect(r.sick, 1);
    expect(r.personal, 1);
    expect(r.otherLeave, 2);
    expect(r.busAbsent, 1);
    expect(r.absent, 1);
    expect(r.confirmed, 9);
    expect(r.rateLabel, '33%*');
    expect(r.days[5].symbol, '請');
  });
  test('legacy confirmation is per status field and cannot produce final rates',
      () {
    final r = report(records: [
      record(1, 'attend', provenance: 'legacyUnverified'),
      record(2, 'attend',
          provenance: 'partiallyConfirmed', confirmed: ['status'])
    ], sessions: [
      ClassSession('a', day(1), SessionStatus.held),
      ClassSession('a', day(2), SessionStatus.held)
    ]).rows.single;
    expect(r.pending, 1);
    expect(r.present, 1);
    expect(r.days[0].symbol, '○?');
    expect(r.isFinal, isFalse);
    expect(report(records: []).rows.single.rate, isNull);
  });
  test('fully confirmed month has final rate and leap year has 29 day columns',
      () {
    final r = report(
        records: [record(1, 'attend')],
        sessions: [ClassSession('a', day(1), SessionStatus.held)]).rows.single;
    expect(r.rateLabel, '100%');
    expect(r.isFinal, isTrue);
    final leap = MonthlyAttendanceService.build(
        month: DateTime(2028, 2),
        site: site,
        students: [],
        enrollments: [],
        records: [],
        sessions: []);
    expect(leap.days, 29);
  });
  test('switching month or revoking access cancels pending PDF download',
      () async {
    final repo = monthlyReportDemoRepository();
    final cubit = MonthlyAttendanceCubit(repo, initialMonth: DateTime(2026, 10))
      ..start();
    await tick();
    expect(cubit.state.canExport, isTrue);
    final gate = Completer<Uint8List>();
    var saved = 0;
    final download = cubit.download((_) => gate.future, (_, __) async {
      saved++;
    });
    expect(cubit.state.exporting, isTrue);
    cubit.selectMonth(DateTime(2026, 11));
    await tick();
    gate.complete(Uint8List(2));
    await download;
    expect(saved, 0);
    expect(cubit.state.report!.rows, isEmpty);
    cubit.selectMonth(DateTime(2026, 10));
    await tick();
    repo.access = null;
    repo.notify();
    await tick();
    expect(cubit.state.report, isNull);
    expect(cubit.state.canExport, isFalse);
    await cubit.close();
    await repo.events.close();
  });
  test(
      'live update invalidates in-flight export and duplicate export is ignored',
      () async {
    final repo = monthlyReportDemoRepository();
    final cubit = MonthlyAttendanceCubit(repo, initialMonth: DateTime(2026, 10))
      ..start();
    await tick();
    final gate = Completer<Uint8List>();
    var saves = 0, builds = 0;
    final pending = cubit.download((_) {
      builds++;
      return gate.future;
    }, (_, __) async {
      saves++;
    });
    await cubit.download((_) async {
      builds++;
      return Uint8List(1);
    }, (_, __) async {
      saves++;
    });
    repo.notify();
    await tick();
    gate.complete(Uint8List(1));
    await pending;
    expect(builds, 1);
    expect(saves, 0);
    expect(cubit.state.exporting, isFalse);
    await cubit.close();
    await repo.events.close();
  });
  test('export failure leaves download available with a visible error',
      () async {
    final repo = monthlyReportDemoRepository();
    final cubit = MonthlyAttendanceCubit(repo, initialMonth: DateTime(2026, 10))
      ..start();
    await tick();
    await cubit.download(
        (_) async => throw StateError('font failed'), (_, __) async {});
    expect(cubit.state.exportError, contains('重試'));
    expect(cubit.state.canExport, isTrue);
    await cubit.close();
    await repo.events.close();
  });
  test('a failed subscription cannot be hidden by another source updating',
      () async {
    final repo = _ErrorRepository();
    final cubit = MonthlyAttendanceCubit(repo, initialMonth: DateTime(2026, 10))
      ..start();
    await tick();
    repo.recordsStream.add(DataSnapshot(repo.records));
    await tick();
    expect(cubit.state.canExport, isTrue);
    repo.recordsStream.addError(StateError('network'));
    await tick();
    expect(cubit.state.error, isNotNull);
    repo.notify();
    await tick();
    expect(cubit.state.error, isNotNull);
    expect(cubit.state.canExport, isFalse);
    repo.recordsStream.add(DataSnapshot(repo.records, fromCache: true));
    await tick();
    expect(cubit.state.report!.fromCache, isTrue);
    expect(cubit.state.canExport, isFalse);
    repo.recordsStream.add(DataSnapshot(repo.records));
    await tick();
    expect(cubit.state.canExport, isTrue);
    await cubit.close();
    await repo.events.close();
    await repo.recordsStream.close();
  });
  test('PDF embeds Chinese font and supports 0, 1, 32 and multi-page long rows',
      () async {
    final demo = monthlyReportDemoRepository(count: 65);
    final base = MonthlyAttendanceService.build(
        month: DateTime(2026, 10),
        site: demo.sites.first,
        students: demo.students,
        enrollments: demo.enrollments,
        records: demo.records,
        sessions: demo.sessions);
    final font = ByteData.sublistView(
        await File('assets/fonts/report/NotoSansTC-Regular.ttf').readAsBytes());
    for (final size in [0, 1, 32, 65]) {
      final selected = base.rows.take(size).toList();
      if (size == 65) {
        selected.add(MonthlyAttendanceRow(
            studentId: 'long',
            name: '合成長姓名測試同學' * 8,
            days: base.rows.first.days));
      }
      final r = MonthlyAttendanceReport(
          month: base.month,
          site: base.site,
          rows: selected,
          recordCount: base.recordCount,
          sessionCount: base.sessionCount);
      final bytes = await MonthlyAttendancePdf.build(r, font);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      final file = File('build/monthly-report-qa/report-$size.pdf');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes);
    }
    await demo.events.close();
  });
  testWidgets(
      'responsive light and dark report screens retain download and month controls',
      (tester) async {
    await tester.runAsync(() async {
      final font = FontLoader('ReportQA')
        ..addFont(Future.value(ByteData.sublistView(
            await File('assets/fonts/report/NotoSansTC-Regular.ttf')
                .readAsBytes())));
      await font.load();
      final fallback = FontLoader('Roboto')
        ..addFont(Future.value(ByteData.sublistView(
            await File('assets/fonts/report/NotoSansTC-Regular.ttf')
                .readAsBytes())));
      await fallback.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    final r = report(records: [record(1, 'attend')]);
    var downloads = 0;
    for (final dark in [false, true]) {
      for (final size in [
        const Size(1024, 768),
        const Size(768, 1024),
        const Size(1194, 834),
        const Size(834, 1194),
        const Size(507, 768)
      ]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        final boundary = GlobalKey();
        await tester.pumpWidget(MaterialApp(
            theme: SystemTheme(defaultDesignThemes().first, dark)
                .materialTheme()
                .copyWith(
                    textTheme: SystemTheme(defaultDesignThemes().first, dark)
                        .materialTheme()
                        .textTheme
                        .apply(fontFamily: 'ReportQA')),
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate
            ],
            locale: const Locale('zh', 'TW'),
            supportedLocales: const [Locale('zh', 'TW')],
            home: RepaintBoundary(
                key: boundary,
                child: Scaffold(
                    body: SafeArea(
                        child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: MonthlyAttendanceView(
                                state: MonthlyAttendanceState(
                                    month: r.month,
                                    sites: [site],
                                    siteId: site.id,
                                    report: r,
                                    loading: false),
                                onMonth: (_) {},
                                onSite: (_) {},
                                onDownload: () => downloads++,
                                onRetry: () {},
                                demo: true)))))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
              'build/monthly-report-qa/${dark ? 'dark' : 'light'}-${size.width.toInt()}x${size.height.toInt()}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        await tester.tap(find.byKey(const ValueKey('download-monthly-pdf')));
        await tester.pump();
      }
    }
    expect(downloads, 10);
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  testWidgets(
      'loading, empty, errors and offline states disable export; login validates locally',
      (tester) async {
    final r = report();
    for (final variant in ['loading', 'empty', 'error', 'offline']) {
      final empty = MonthlyAttendanceReport(
          month: r.month,
          site: site,
          rows: const [],
          recordCount: 0,
          sessionCount: 0);
      final cached = MonthlyAttendanceReport(
          month: r.month,
          site: site,
          rows: r.rows,
          recordCount: 0,
          sessionCount: 0,
          fromCache: true);
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: MonthlyAttendanceView(
                  state: MonthlyAttendanceState(
                      month: r.month,
                      loading: variant == 'loading',
                      error: variant == 'error' ? '網路錯誤' : null,
                      report: variant == 'empty'
                          ? empty
                          : variant == 'offline'
                              ? cached
                              : r),
                  onMonth: (_) {},
                  onSite: (_) {},
                  onDownload: () {},
                  onRetry: () {}))));
      await tester.pump();
      expect(
          tester
              .widget<ElevatedButton>(
                  find.byKey(const ValueKey('download-monthly-pdf')))
              .onPressed,
          isNull);
    }
    var calls = 0;
    await tester.pumpWidget(MaterialApp(
        home: AdminLoginView(
            onDemo: () {},
            onLogin: (_, __) async {
              calls++;
              return null;
            })));
    await tester.tap(find.text('登入後台'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(find.text('請輸入有效的 Email'), findsOneWidget);
    expect(find.text('請輸入密碼'), findsOneWidget);
  });
}

class _ErrorRepository extends MemoryRosterRepository {
  _ErrorRepository()
      : super(
            access: RosterAccess('test', 'manager', ['a']),
            sites: [site],
            students: [const StudentSummary('one', '合成學生')],
            enrollments: [period('one')],
            records: [record(1, 'attend')],
            sessions: [ClassSession('a', day(1), SessionStatus.held)]);
  final recordsStream =
      StreamController<DataSnapshot<List<DailyRecord>>>.broadcast();
  @override
  Stream<DataSnapshot<List<DailyRecord>>> watchRecords(
          String kind, String locationId,
          {BusinessDate? date,
          String? studentId,
          BusinessDate? from,
          BusinessDate? to,
          int? limit = 100,
          String? beforeDate}) =>
      recordsStream.stream;
}
