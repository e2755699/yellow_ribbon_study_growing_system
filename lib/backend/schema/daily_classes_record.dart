import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class DailyClassesRecord extends FirestoreRecord {
  DailyClassesRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "date" field.
  DateTime? _date;
  DateTime? get date => _date;
  bool hasDate() => _date != null;

  // "student_id" field.
  DocumentReference? _studentId;
  DocumentReference? get studentId => _studentId;
  bool hasStudentId() => _studentId != null;

  // "class_id" field.
  DocumentReference? _classId;
  DocumentReference? get classId => _classId;
  bool hasClassId() => _classId != null;

  void _initializeFields() {
    _date = snapshotData['date'] as DateTime?;
    _studentId = snapshotData['student_id'] as DocumentReference?;
    _classId = snapshotData['class_id'] as DocumentReference?;
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('daily_classes');

  static Stream<DailyClassesRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => DailyClassesRecord.fromSnapshot(s));

  static Future<DailyClassesRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => DailyClassesRecord.fromSnapshot(s));

  static DailyClassesRecord fromSnapshot(DocumentSnapshot snapshot) =>
      DailyClassesRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static DailyClassesRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      DailyClassesRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'DailyClassesRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is DailyClassesRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createDailyClassesRecordData({
  DateTime? date,
  DocumentReference? studentId,
  DocumentReference? classId,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'date': date,
      'student_id': studentId,
      'class_id': classId,
    }.withoutNulls,
  );

  return firestoreData;
}

class DailyClassesRecordDocumentEquality
    implements Equality<DailyClassesRecord> {
  const DailyClassesRecordDocumentEquality();

  @override
  bool equals(DailyClassesRecord? e1, DailyClassesRecord? e2) {
    return e1?.date == e2?.date &&
        e1?.studentId == e2?.studentId &&
        e1?.classId == e2?.classId;
  }

  @override
  int hash(DailyClassesRecord? e) =>
      const ListEquality().hash([e?.date, e?.studentId, e?.classId]);

  @override
  bool isValidKey(Object? o) => o is DailyClassesRecord;
}
