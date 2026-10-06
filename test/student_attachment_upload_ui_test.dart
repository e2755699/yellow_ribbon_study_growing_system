import 'package:yellow_ribbon_study_growing_system/design_system/domain/theme_defaults.dart';
import 'package:yellow_ribbon_study_growing_system/design_system/presentation/system_theme.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_state.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/attachment_ref.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/drive_attachment_store.dart';
import 'package:yellow_ribbon_study_growing_system/domain/service/storage_service.dart';
import 'package:yellow_ribbon_study_growing_system/main/pages/student_detail_page/student_detail_main_section.dart';
import 'domain/service/student_attachment_service_test.dart' show FileRepo;

class FixturePicker extends FilePicker {
  @override
  Future<FilePickerResult?> pickFiles(
          {String? dialogTitle,
          String? initialDirectory,
          FileType type = FileType.any,
          List<String>? allowedExtensions,
          Function(FilePickerStatus)? onFileLoading,
          bool allowCompression = true,
          int compressionQuality = 30,
          bool allowMultiple = false,
          bool withData = false,
          bool withReadStream = false,
          bool lockParentWindow = false,
          bool readSequential = false}) async =>
      FilePickerResult([
        PlatformFile(
            name: '驗收.xlsx',
            size: 8,
            bytes: Uint8List.fromList([80, 75, 3, 4, 0, 0, 0, 0]))
      ]);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      final font = await File(const String.fromEnvironment('CAPTURE_FONT'))
          .readAsBytes();
      for (final family in ['Ahem', 'Roboto']) {
        await (FontLoader(family)
              ..addFont(Future.value(ByteData.sublistView(font))))
            .load();
      }
    }
  });
  for (final brightness in Brightness.values) {
    for (final size in [
      const Size(1024, 768),
      const Size(768, 1024),
      const Size(1194, 834),
      const Size(834, 1194),
      const Size(507, 768)
    ]) {
      testWidgets(
          'actual upload button saves only Drive reference at $size $brightness',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
                const MethodChannel('PonnamKarthik/fluttertoast'),
                (_) async => true);

        FilePicker.platform = FixturePicker();

        final events = <String>[];
        final repo = FileRepo(events)..profile = null;
        GetIt.I.registerSingleton<StudentsRepo>(repo);
        addTearDown(() => GetIt.I.reset());
        final detail = StudentDetail.empty().copyWith(
            id: 'student',
            name: '原名字',
            locationId: 'demo',
            classLocation: '合成據點',
            enrollmentStartDate: '2026-10-01');
        final cubit = StudentDetailCubit(
            StudentDetailLoaded(detail: detail, operate: Operate.edit));
        addTearDown(cubit.close);
        final storage = StorageService(
            useDrive: true,
            attachmentStore: DriveAttachmentStore(
                token: () async => 'test-token',
                account: () => 'teacher',
                client: MockClient((r) async {
                  expect(r.method, 'POST');
                  expect(r.headers['Authorization'], 'Bearer test-token');
                  expect(r.bodyBytes, [80, 75, 3, 4, 0, 0, 0, 0]);
                  events.add('upload');
                  return http.Response('{"fileId":"synthetic-file"}', 201);
                })));
        final captureKey = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(
            key: captureKey,
            child: ScreenUtilInit(
                designSize: const Size(2360, 1640),
                builder: (_, __) => MaterialApp(
                    theme: SystemTheme(defaultDesignThemes().first,
                            brightness == Brightness.dark)
                        .materialTheme(),
                    home: Scaffold(
                        body: BlocProvider.value(
                            value: cubit,
                            child: StudentDetailMainSection(
                                studentDetail: detail,
                                storageService: storage)))))));
        await tester.pumpAndSettle();
        await tester.enterText(
            find.widgetWithText(TextFormField, '名字'), '尚未儲存的姓名');
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.scrollUntilVisible(find.text('上傳檔案'), 500,
            scrollable: find.byType(Scrollable).first);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('上傳檔案'));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          await tester.tap(find.text('上傳檔案'));
          for (var i = 0; i < 500 && repo.profile == null; i++) {
            await Future<void>.delayed(const Duration(milliseconds: 10));
          }
        });
        await tester.pumpAndSettle();
        expect(events.first, 'upload');
        expect(events.last, startsWith('save:yrfile:'));
        expect(AttachmentRef.parse(repo.profile)!.fileId, 'synthetic-file');
        expect(cubit.state.detail.profileFileName, repo.profile);
        expect(find.text('驗收.xlsx'), findsOneWidget);
        expect(find.text('尚未儲存的姓名'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('CAPTURE_UI')) {
          final boundary = captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          await tester.runAsync(() async {
            final image = await boundary.toImage();
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
                '.release-private/drive-ui/upload-${size.width.toInt()}x${size.height.toInt()}-${brightness.name}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(png!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
