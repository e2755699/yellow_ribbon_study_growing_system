import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_state.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';
import 'package:yellow_ribbon_study_growing_system/domain/roster/roster_command_failure.dart';
import 'student_detail_cubit_test.dart' show MemoryStudentsRepo;

class RecoveryStudentsRepo extends MemoryStudentsRepo {
  final source = StreamController<StudentDetail?>.broadcast();
  final submissions = <StudentDetail>[];
  Object? createError;
  @override
  Stream<StudentDetail?> watchById(String id) => source.stream;
  @override
  Future<String?> create(StudentDetail student) async {
    submissions.add(student);
    if (createError != null) throw createError!;
    students[student.id!] = student;
    return student.id;
  }
}

void main() {
  late RecoveryStudentsRepo repo;
  late StudentDetailCubit cubit;
  final original = StudentDetail.empty().copyWith(
      name: 'Synthetic',
      locationId: 'old-site',
      enrollmentStartDate: '2026-10-01');
  setUp(() {
    repo = RecoveryStudentsRepo();
    GetIt.I.registerSingleton<StudentsRepo>(repo);
    cubit =
        StudentDetailCubit(StudentDetailInitial(detail: StudentDetail.empty()));
  });
  tearDown(() async {
    await cubit.close();
    await repo.source.close();
    await GetIt.I.reset();
  });

  for (final code in [
    'invalid-argument',
    'failed-precondition',
    'permission-denied'
  ]) {
    test('definite $code allows corrected creation with a fresh request',
        () async {
      cubit.createStudentDetail(operate: Operate.create);
      repo.createError = RosterCommandFailure(code);
      expect(await cubit.create(original), false);
      repo.createError = null;
      final corrected = original.copyWith(
          locationId: 'new-site',
          enrollmentStartDate: '2026-09-01',
          name: 'Corrected');
      expect(await cubit.create(corrected), true);
      expect(repo.submissions.last.locationId, 'new-site');
      expect(repo.submissions.last.enrollmentStartDate, '2026-09-01');
      expect(repo.submissions.last.name, 'Corrected');
      expect(repo.submissions.last.id, isNot(repo.submissions.first.id));
      expect(repo.students.length, 1);
    });
  }

  test(
      'unknown result followed by rejection still retries the original request',
      () async {
    cubit.createStudentDetail(operate: Operate.create);
    repo.createError = const RosterCommandFailure('deadline-exceeded');
    expect(await cubit.create(original), false);
    final edited = original.copyWith(name: 'Newer draft');
    repo.createError = const RosterCommandFailure('permission-denied');
    expect(await cubit.create(edited), false);
    expect((cubit.state as StudentDetailError).message, contains('尚未確認'));
    repo.createError = null;
    expect(await cubit.create(edited), true);
    expect(repo.submissions.map((s) => s.id).toSet().length, 1);
    expect(repo.submissions.every((s) => s.name == 'Synthetic'), true);
    expect(repo.updatedStudent!.name, 'Newer draft');
    expect(repo.students.length, 1);
  });

  test(
      'confirmed creation followed by rejected profile patch keeps the same ID',
      () async {
    cubit.createStudentDetail(operate: Operate.create);
    repo.createError = const RosterCommandFailure('deadline-exceeded');
    await cubit.create(original);
    repo.createError = null;
    repo.failUpdate = true;
    final edited = original.copyWith(name: 'Newer draft');
    expect(await cubit.create(edited), false);
    expect((cubit.state as StudentDetailError).message, contains('學生已建立'));
    repo.failUpdate = false;
    expect(await cubit.create(edited), true);
    expect(repo.submissions.map((s) => s.id).toSet().length, 1);
    expect(repo.students.length, 1);
    expect(repo.updatedStudent!.name, 'Newer draft');
  });

  Future<void> openEditor() async {
    final loading = cubit.loadStudentById('synthetic', operate: Operate.edit);
    // Allow the subscription setup's cancellation awaits to complete.
    await Future<void>.delayed(Duration.zero);
    repo.source.add(original.copyWith(id: 'synthetic'));
    await loading;
  }

  test('transient error and recovery retain edit state and original save base',
      () async {
    await openEditor();
    final failed = cubit.stream.first;
    repo.source.addError(TimeoutException('network'));
    await failed;
    expect(cubit.state.isEdit, true);
    expect(cubit.state.detail.id, 'synthetic');
    expect(cubit.hasUnsavedChanges(), true);
    repo.source.add(original.copyWith(id: 'synthetic', name: 'Remote change'));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.detail.name, 'Synthetic');
    expect(cubit.state.isEdit, true);
    expect(await cubit.save(cubit.state.detail.copyWith(name: 'Local draft')),
        true);
    expect(repo.updatedStudent!.name, 'Local draft');
  });

  test('authorization loss still clears the profile and edit state', () async {
    await openEditor();
    final failed = cubit.stream.first;
    repo.source.addError(const StudentProfileAccessDenied());
    await failed;
    expect(cubit.state.detail.id, isNull);
    expect(cubit.state.isView, true);
    expect(cubit.hasUnsavedChanges(), false);
  });

  test('deleted or inaccessible profile still clears the editor', () async {
    await openEditor();
    final missing = cubit.stream.first;
    repo.source.add(null);
    await missing;
    expect(cubit.state.detail.id, isNull);
    expect(cubit.state.isView, true);
  });
}
