import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_cubit.dart';
import 'package:yellow_ribbon_study_growing_system/domain/bloc/student_detial_cubit/student_detail_state.dart';
import 'package:yellow_ribbon_study_growing_system/domain/enum/operate.dart';
import 'package:yellow_ribbon_study_growing_system/domain/model/student/student_detail.dart';
import 'package:yellow_ribbon_study_growing_system/domain/repo/students_repo.dart';

// Implements the repository without constructing its Firebase client.
class MemoryStudentsRepo implements StudentsRepo {
  final students = <String, StudentDetail>{};
  String? createResult = 'generated-student-id';
  String? updatedId;
  StudentDetail? updatedStudent;
  bool failUpdate = false;

  @override
  Future<StudentDetail?> getById(String id) async => students[id];

  @override
  Future<String?> create(StudentDetail student) async {
    final id = createResult;
    if (id != null) students[id] = student.copyWith(id: id);
    return id;
  }

  @override
  Future<void> update(String id, StudentDetail student) async {
    if (failUpdate) throw StateError('offline');
    updatedId = id;
    updatedStudent = student;
    students[id] = student;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MemoryStudentsRepo repo;
  late StudentDetailCubit cubit;

  setUp(() {
    repo = MemoryStudentsRepo();
    GetIt.I.registerSingleton<StudentsRepo>(repo);
    cubit = StudentDetailCubit(
      StudentDetailInitial(detail: StudentDetail.empty()),
    );
  });

  tearDown(() async {
    await cubit.close();
    await GetIt.I.reset();
  });

  test('create mode opens an empty editable form instead of staying loading',
      () {
    cubit.createStudentDetail(operate: Operate.create);
    expect(cubit.state, isA<StudentDetailLoaded>());
    expect(cubit.state.isCreate, isTrue);
    expect(cubit.state.detail.id, isNull);
    expect(cubit.hasUnsavedChanges(), isTrue);
  });

  test('load an existing student with attachment in edit mode', () async {
    repo.students['student-1'] = StudentDetail.empty().copyWith(
      id: 'student-1',
      name: '測試學生',
      profileFileName: 'student-1.pdf',
    );
    await cubit.loadStudentById('student-1', operate: Operate.edit);
    expect(cubit.state, isA<StudentDetailLoaded>());
    expect(cubit.state.detail.name, '測試學生');
    expect(cubit.state.detail.profileFileName, 'student-1.pdf');
    expect(cubit.state.isEdit, isTrue);
  });

  test('missing student shows an error instead of an empty loaded record',
      () async {
    await cubit.loadStudentById('missing');
    expect(cubit.state, isA<StudentDetailError>());
    expect((cubit.state as StudentDetailError).message, '找不到學生資料');
  });

  test('editing preserves student data and marks the form unsaved', () {
    final student =
        StudentDetail.empty().copyWith(id: 'student-1', name: '測試學生');
    cubit.loadStudentDetail(student);
    expect(cubit.hasUnsavedChanges(), isFalse);
    cubit.edit();
    expect(cubit.state.isEdit, isTrue);
    expect(cubit.state.detail, same(student));
    expect(cubit.hasUnsavedChanges(), isTrue);
  });

  test('saving edited student updates the right record and returns to view',
      () async {
    final student =
        StudentDetail.empty().copyWith(id: 'student-1', name: '更新姓名');
    cubit.loadStudentDetail(student, operate: Operate.edit);
    final saved = cubit.stream.first.timeout(const Duration(seconds: 3));
    cubit.save(student);
    await saved;
    expect(repo.updatedId, 'student-1');
    expect(repo.updatedStudent?.name, '更新姓名');
    expect(cubit.state.isView, isTrue);
  });

  test(
      'syncing a removed attachment preserves the edit draft without saving it',
      () async {
    final student = StudentDetail.empty().copyWith(
      id: 'student-1',
      name: '測試學生',
      guardianName: '測試監護人',
      profileFileName: 'old.pdf',
    );
    cubit.loadStudentDetail(student, operate: Operate.edit);
    cubit.syncProfileFile(null);
    final expected = student.toJson()..['profileFileName'] = null;
    expect(cubit.state.detail.toJson(), expected);
    expect(repo.updatedStudent, isNull);
    expect(cubit.state.isEdit, isTrue);
    expect(cubit.state.detail.profileFileName, isNull);
  });

  test('created student retains generated ID for subsequent attachment uploads',
      () async {
    cubit.createStudentDetail(operate: Operate.create);
    final saved = cubit.stream.first.timeout(const Duration(seconds: 3));
    await cubit.create(StudentDetail.empty().copyWith(name: '測試新生'));
    await saved;
    expect(cubit.state.detail.id, 'generated-student-id');
  });

  test('failed creation must not emit a successful view state', () async {
    repo.createResult = null;
    cubit.createStudentDetail(operate: Operate.create);
    final result = cubit.stream.first.timeout(const Duration(seconds: 3));
    await cubit.create(StudentDetail.empty());
    expect(await result, isA<StudentDetailError>());
    expect(cubit.state.isCreate, isTrue);
  });

  test('failed update retains edited data for retry and returns false',
      () async {
    repo.failUpdate = true;
    final student =
        StudentDetail.empty().copyWith(id: 'student-1', name: '未儲存姓名');
    cubit.loadStudentDetail(student, operate: Operate.edit);
    expect(await cubit.save(student), isFalse);
    expect(cubit.state, isA<StudentDetailError>());
    expect(cubit.state.detail.name, '未儲存姓名');
    expect(cubit.state.isEdit, isTrue);
    repo.failUpdate = false;
    expect(await cubit.save(cubit.state.detail), isTrue);
    expect(repo.updatedStudent?.name, '未儲存姓名');
  });
}
