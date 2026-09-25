import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/service/storage_service.dart';
import 'package:yellow_ribbon_study_growing_system/domain/service/student_attachment_service.dart';

class FileRepo implements StudentsRepo {
  FileRepo(this.events);
  final List<String> events;
  String? profile = 'old.pdf';
  String? avatar = 'old.png';
  bool failSave = false;
  @override
  Future<void> updateProfileFile(String id, String? file) async {
    events.add('save:$file');
    if (failSave) throw StateError('offline');
    profile = file;
  }

  @override
  Future<void> updateAvatar(String id, String? file) async {
    events.add('avatar:$file');
    if (failSave) throw StateError('offline');
    avatar = file;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MemoryStorage implements StorageService {
  MemoryStorage(this.events);
  final List<String> events;
  String? uploadedName = 'new.pdf';
  bool failDelete = false;
  final files = <String>{'old.pdf', 'old.png'};
  @override
  Future<String?> uploadStudentProfile(String id, PlatformFile file) async {
    events.add('upload');
    if (uploadedName != null) files.add(uploadedName!);
    return uploadedName;
  }

  @override
  Future<String?> uploadStudentAvatar(String id, XFile file) async {
    events.add('upload-avatar');
    if (uploadedName != null) files.add(uploadedName!);
    return uploadedName;
  }

  @override
  Future<bool> deleteProfileFile(String name) async {
    events.add('delete:$name');
    if (failDelete) return false;
    files.remove(name);
    return true;
  }

  @override
  Future<bool> deleteAvatar(String name) => deleteProfileFile(name);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late List<String> events;
  late FileRepo repo;
  late MemoryStorage storage;
  late StudentAttachmentService service;
  final file = PlatformFile(
      name: 'test.pdf', size: 3, bytes: Uint8List.fromList([1, 2, 3]));

  setUp(() {
    events = [];
    repo = FileRepo(events);
    storage = MemoryStorage(events);
    service = StudentAttachmentService(students: repo, storage: storage);
  });

  test('replacement uploads and persists before removing the old file',
      () async {
    final result = await service.replaceProfile('s1', 'old.pdf', file);
    expect(events, ['upload', 'save:new.pdf', 'delete:old.pdf']);
    expect(repo.profile, 'new.pdf');
    expect(result.cleanupFailed, isFalse);
  });

  test('upload failure preserves old file and reference', () async {
    storage.uploadedName = null;
    await expectLater(
        service.replaceProfile('s1', 'old.pdf', file), throwsStateError);
    expect(events, ['upload']);
    expect(storage.files, contains('old.pdf'));
    expect(repo.profile, 'old.pdf');
  });

  test('Firestore failure rolls back the new upload only', () async {
    repo.failSave = true;
    await expectLater(
        service.replaceProfile('s1', 'old.pdf', file), throwsStateError);
    expect(events, ['upload', 'save:new.pdf', 'delete:new.pdf']);
    expect(storage.files, contains('old.pdf'));
    expect(storage.files, isNot(contains('new.pdf')));
    expect(repo.profile, 'old.pdf');
  });

  test(
      'old-file cleanup failure keeps the new reference and reports partial cleanup',
      () async {
    storage.failDelete = true;
    final result = await service.replaceProfile('s1', 'old.pdf', file);
    expect(result.cleanupFailed, isTrue);
    expect(repo.profile, 'new.pdf');
    expect(storage.files, containsAll(['old.pdf', 'new.pdf']));
  });

  test('delete clears the reference then removes the file', () async {
    await service.deleteProfile('s1', 'old.pdf');
    expect(events, ['save:null', 'delete:old.pdf']);
    expect(repo.profile, isNull);
    expect(storage.files, isNot(contains('old.pdf')));
  });

  test('failed deletion restores the reference and preserves the file',
      () async {
    storage.failDelete = true;
    await expectLater(service.deleteProfile('s1', 'old.pdf'), throwsStateError);
    expect(events, ['save:null', 'delete:old.pdf', 'save:old.pdf']);
    expect(repo.profile, 'old.pdf');
    expect(storage.files, contains('old.pdf'));
  });

  test('failed reference removal never deletes the file', () async {
    repo.failSave = true;
    await expectLater(service.deleteProfile('s1', 'old.pdf'), throwsStateError);
    expect(events, ['save:null']);
    expect(storage.files, contains('old.pdf'));
  });

  test('avatar replacement follows the same safe persistence order', () async {
    storage.uploadedName = 'new.png';
    await service.replaceAvatar(
        's1', 'old.png', XFile.fromData(Uint8List(1), name: 'photo.png'));
    expect(events, ['upload-avatar', 'avatar:new.png', 'delete:old.png']);
    expect(repo.avatar, 'new.png');
  });
}
