import 'dart:async';

import 'package:collection/collection.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/util/schema_util.dart';
import '/backend/schema/enums/enums.dart';

import 'index.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ClassInfoRecord extends FirestoreRecord {
  ClassInfoRecord._(
    super.reference,
    super.data,
  ) {
    _initializeFields();
  }

  // "location" field.
  Location? _location;
  Location? get location => _location;
  bool hasLocation() => _location != null;

  void _initializeFields() {
    _location = deserializeEnum<Location>(snapshotData['location']);
  }

  static CollectionReference get collection =>
      FirebaseFirestore.instance.collection('class_info');

  static Stream<ClassInfoRecord> getDocument(DocumentReference ref) =>
      ref.snapshots().map((s) => ClassInfoRecord.fromSnapshot(s));

  static Future<ClassInfoRecord> getDocumentOnce(DocumentReference ref) =>
      ref.get().then((s) => ClassInfoRecord.fromSnapshot(s));

  static ClassInfoRecord fromSnapshot(DocumentSnapshot snapshot) =>
      ClassInfoRecord._(
        snapshot.reference,
        mapFromFirestore(snapshot.data() as Map<String, dynamic>),
      );

  static ClassInfoRecord getDocumentFromData(
    Map<String, dynamic> data,
    DocumentReference reference,
  ) =>
      ClassInfoRecord._(reference, mapFromFirestore(data));

  @override
  String toString() =>
      'ClassInfoRecord(reference: ${reference.path}, data: $snapshotData)';

  @override
  int get hashCode => reference.path.hashCode;

  @override
  bool operator ==(other) =>
      other is ClassInfoRecord &&
      reference.path.hashCode == other.reference.path.hashCode;
}

Map<String, dynamic> createClassInfoRecordData({
  Location? location,
}) {
  final firestoreData = mapToFirestore(
    <String, dynamic>{
      'location': location,
    }.withoutNulls,
  );

  return firestoreData;
}

class ClassInfoRecordDocumentEquality implements Equality<ClassInfoRecord> {
  const ClassInfoRecordDocumentEquality();

  @override
  bool equals(ClassInfoRecord? e1, ClassInfoRecord? e2) {
    return e1?.location == e2?.location;
  }

  @override
  int hash(ClassInfoRecord? e) => const ListEquality().hash([e?.location]);

  @override
  bool isValidKey(Object? o) => o is ClassInfoRecord;
}
