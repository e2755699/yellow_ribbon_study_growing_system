import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/request_timeout.dart';
import 'package:collection/collection.dart';
import '../service/record_merge.dart';

/// Compatibility writer used before the v2 cutover. All reads precede writes.
class LegacyDailyRecordStore {
  final FirebaseFirestore firestore;
  LegacyDailyRecordStore(this.firestore);

  Future<void> save(String collection, String documentId,
      Map<String, dynamic> submitted, Map<String, dynamic>? expected) async {
    final ref = firestore.collection(collection).doc(documentId);
    final incoming = (submitted['records'] as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList();
    final bases = {
      for (final row in (expected?['records'] as List? ?? []))
        row['sid'] as String: Map<String, dynamic>.from(row as Map),
    };
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final current = {
        for (final row in (snapshot.data()?['records'] as List? ?? []))
          row['sid'] as String: Map<String, dynamic>.from(row as Map),
      };
      final deltas = <String, int>{};
      final events = <String, Map<String, dynamic>>{};
      for (final row in incoming) {
        final sid = row['sid'] as String;
        final base = bases[sid];
        if (base != null && const DeepCollectionEquality().equals(base, row))
          continue;
        // Existing data cannot be overwritten without the loaded baseline.
        if (base == null &&
            current.containsKey(sid) &&
            !const DeepCollectionEquality().equals(current[sid], row)) {
          throw RecordConflict(sid, row.keys.toSet());
        }
        final previous = current[sid];
        final merged = mergeRecord(
            recordId: sid,
            current: previous ?? base ?? {},
            base: base ?? {},
            submitted: row,
            atomicGroups: collection == 'daily_attendance'
                ? [
                    {'status', 'leaveReason'}
                  ]
                : []);
        if (collection == 'daily_performances') {
          final wasExcellent = previous?['performanceRating'] == 'excellent';
          final excellent = merged['performanceRating'] == 'excellent';
          final active = previous?['ribbonAwardActive'] == true;
          final delta = excellent && !wasExcellent
              ? 1
              : !excellent && wasExcellent && active
                  ? -1
                  : 0;
          if (delta != 0) {
            final revision = (previous?['ribbonRevision'] as int? ?? 0) + 1;
            merged['ribbonAwardActive'] = delta > 0;
            merged['ribbonRevision'] = revision;
            deltas[sid] = (deltas[sid] ?? 0) + delta;
            events[[documentId, sid, revision].join('_')] = {
              'studentId': sid,
              'source': ref.path,
              'delta': delta,
              'kind': delta > 0 ? 'award' : 'reversal',
              'createdAt': FieldValue.serverTimestamp(),
            };
          }
        }
        current[sid] = merged;
      }
      final counts = <String, DocumentSnapshot<Map<String, dynamic>>>{};
      for (final sid in deltas.keys) {
        counts[sid] = await transaction
            .get(firestore.collection('yellow_ribbon_counts').doc(sid));
      }
      transaction.set(
          ref,
          {
            ...submitted,
            'records': current.values.toList(),
          },
          SetOptions(merge: true));
      for (final entry in deltas.entries) {
        final data = counts[entry.key]!.data();
        transaction.set(
            counts[entry.key]!.reference,
            {
              'totalCount': (data?['totalCount'] as int? ?? 0) + entry.value,
              'usedCount': data?['usedCount'] as int? ?? 0,
              'lastUpdated': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      }
      for (final event in events.entries) {
        transaction.set(
            firestore.collection('ribbon_events').doc(event.key), event.value);
      }
    }, timeout: requestTimeout).withRequestTimeout();
  }
}
