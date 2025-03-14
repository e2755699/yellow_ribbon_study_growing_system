// ignore_for_file: unnecessary_getters_setters

import 'package:cloud_firestore/cloud_firestore.dart';

import '/backend/schema/util/firestore_util.dart';
import '/backend/schema/enums/enums.dart';

import '/flutter_flow/flutter_flow_util.dart';

class StudentStruct extends FFFirebaseStruct {
  StudentStruct({
    String? name,
    int? phone,
    Location? location,
    FirestoreUtilData firestoreUtilData = const FirestoreUtilData(),
  })  : _name = name,
        _phone = phone,
        _location = location,
        super(firestoreUtilData);

  // "name" field.
  String? _name;
  String get name => _name ?? '';
  set name(String? val) => _name = val;

  bool hasName() => _name != null;

  // "phone" field.
  int? _phone;
  int get phone => _phone ?? 0;
  set phone(int? val) => _phone = val;

  void incrementPhone(int amount) => phone = phone + amount;

  bool hasPhone() => _phone != null;

  // "location" field.
  Location? _location;
  Location get location => _location ?? Location.Yongkang;
  set location(Location? val) => _location = val;

  bool hasLocation() => _location != null;

  static StudentStruct fromMap(Map<String, dynamic> data) => StudentStruct(
        name: data['name'] as String?,
        phone: castToType<int>(data['phone']),
        location: deserializeEnum<Location>(data['location']),
      );

  static StudentStruct? maybeFromMap(dynamic data) =>
      data is Map ? StudentStruct.fromMap(data.cast<String, dynamic>()) : null;

  Map<String, dynamic> toMap() => {
        'name': _name,
        'phone': _phone,
        'location': _location?.serialize(),
      }.withoutNulls;

  @override
  Map<String, dynamic> toSerializableMap() => {
        'name': serializeParam(
          _name,
          ParamType.String,
        ),
        'phone': serializeParam(
          _phone,
          ParamType.int,
        ),
        'location': serializeParam(
          _location,
          ParamType.Enum,
        ),
      }.withoutNulls;

  static StudentStruct fromSerializableMap(Map<String, dynamic> data) =>
      StudentStruct(
        name: deserializeParam(
          data['name'],
          ParamType.String,
          false,
        ),
        phone: deserializeParam(
          data['phone'],
          ParamType.int,
          false,
        ),
        location: deserializeParam<Location>(
          data['location'],
          ParamType.Enum,
          false,
        ),
      );

  @override
  String toString() => 'StudentStruct(${toMap()})';

  @override
  bool operator ==(Object other) {
    return other is StudentStruct &&
        name == other.name &&
        phone == other.phone &&
        location == other.location;
  }

  @override
  int get hashCode => const ListEquality().hash([name, phone, location]);
}

StudentStruct createStudentStruct({
  String? name,
  int? phone,
  Location? location,
  Map<String, dynamic> fieldValues = const {},
  bool clearUnsetFields = true,
  bool create = false,
  bool delete = false,
}) =>
    StudentStruct(
      name: name,
      phone: phone,
      location: location,
      firestoreUtilData: FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
        delete: delete,
        fieldValues: fieldValues,
      ),
    );

StudentStruct? updateStudentStruct(
  StudentStruct? student, {
  bool clearUnsetFields = true,
  bool create = false,
}) =>
    student
      ?..firestoreUtilData = FirestoreUtilData(
        clearUnsetFields: clearUnsetFields,
        create: create,
      );

void addStudentStructData(
  Map<String, dynamic> firestoreData,
  StudentStruct? student,
  String fieldName, [
  bool forFieldValue = false,
]) {
  firestoreData.remove(fieldName);
  if (student == null) {
    return;
  }
  if (student.firestoreUtilData.delete) {
    firestoreData[fieldName] = FieldValue.delete();
    return;
  }
  final clearFields =
      !forFieldValue && student.firestoreUtilData.clearUnsetFields;
  if (clearFields) {
    firestoreData[fieldName] = <String, dynamic>{};
  }
  final studentData = getStudentFirestoreData(student, forFieldValue);
  final nestedData = studentData.map((k, v) => MapEntry('$fieldName.$k', v));

  final mergeFields = student.firestoreUtilData.create || clearFields;
  firestoreData
      .addAll(mergeFields ? mergeNestedFields(nestedData) : nestedData);
}

Map<String, dynamic> getStudentFirestoreData(
  StudentStruct? student, [
  bool forFieldValue = false,
]) {
  if (student == null) {
    return {};
  }
  final firestoreData = mapToFirestore(student.toMap());

  // Add any Firestore field values
  student.firestoreUtilData.fieldValues.forEach((k, v) => firestoreData[k] = v);

  return forFieldValue ? mergeNestedFields(firestoreData) : firestoreData;
}

List<Map<String, dynamic>> getStudentListFirestoreData(
  List<StudentStruct>? students,
) =>
    students?.map((e) => getStudentFirestoreData(e, true)).toList() ?? [];
