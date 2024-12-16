import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class StudentDetailRecord extends FirestoreRecord {
  StudentDetailRecord._(
    DocumentReference reference,
    Map<String, dynamic> data,
  ) : super(reference, data) {
    _initializeFields();
  }

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  bool hasName() => _name != null;

  // "school" field.
  String? _school;
  String get school => _school ?? '';
  bool hasSchool() => _school != null;

  // "phone" field.
  String? _phone;
  String get phone => _phone ?? '';
  bool hasPhone() => _phone != null;

  // "class_id" field.
  DocumentReference? _classId;
  DocumentReference? get classId => _classId;
  bool hasClassId() => _classId != null;

  void _initializeFields() {
    _name = snapshotData['name'] as String?;
    _school = snapshotData['school'] as String?;
    _phone = snapshotData['phone'] as String?;
    _classId = snapshotData['class_id'] as DocumentReference?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('student_profiles');

  static Stream<StudentDetailRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => StudentDetailRecord.fromSnapshot(s));

  static Future<StudentDetailRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => StudentDetailRecord.fromSnapshot(s));

  static StudentDetailRecord fromSnapshot(DocumentSnapshot snapshot) =>
      StudentDetailRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static StudentDetailRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      StudentDetailRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'StudentProfilesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is StudentDetailRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createStudentProfilesRecordData({
  String? name,
  String? school,
  String? phone,
  DocumentReference? classId,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'name': name,
      'school': school,
      'phone': phone,
      'class_id': classId,
    }.withoutNulls,
  );

  return firestoreData;
}

class StudentProfilesRecordDocumentEquality
    implements Equality<StudentDetailRecord> {
  const StudentProfilesRecordDocumentEquality();

  @override
  bool equals(StudentDetailRecord? e1, StudentDetailRecord? e2) {
    return e1?.name == e2?.name &&
        e1?.school == e2?.school &&
        e1?.phone == e2?.phone &&
        e1?.classId == e2?.classId;
  }

  @override
  int hash(StudentDetailRecord? e) =>
      const ListEquality().hash([e?.name, e?.school, e?.phone, e?.classId]);

  @override
  bool isValidKey(Object? o) => o is StudentDetailRecord;
}
