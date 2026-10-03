import 'package:collection/collection.dart';

class RecordConflict implements Exception {
  final String recordId;
  final Set<String> fields;
  const RecordConflict(this.recordId, this.fields);
  @override
  String toString() => '資料已被其他人修改，請重新核對：' + recordId;
}

/// Three-way merge: apply only local changes, preserving unrelated remote data.
/// The caller supplies a server snapshot inside a transaction.
Map<String, dynamic> mergeRecord({
  required String recordId,
  required Map<String, dynamic> current,
  required Map<String, dynamic> base,
  required Map<String, dynamic> submitted,
  List<Set<String>> atomicGroups = const [],
}) {
  const equality = DeepCollectionEquality();
  final changed = submitted.keys
      .where((key) => !equality.equals(submitted[key], base[key]))
      .toSet();
  for (final group in atomicGroups) {
    if (group.any(changed.contains)) changed.addAll(group);
  }
  final conflicts = changed
      .where((key) =>
          !equality.equals(current[key], base[key]) &&
          !equality.equals(current[key], submitted[key]))
      .toSet();
  if (conflicts.isNotEmpty) throw RecordConflict(recordId, conflicts);
  return {...current, for (final key in changed) key: submitted[key]};
}
