import 'package:yellow_ribbon_study_growing_system/domain/utils/request_timeout.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:uuid/uuid.dart';
import '../model/yellow_ribbon/yellow_ribbon_count.dart';
import '../roster/roster_repository.dart';

class YellowRibbonRepo {
  final FirebaseFirestore firestore;
  final RosterRepository roster;
  YellowRibbonRepo({required this.roster, FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;
  Stream<Map<String, YellowRibbonCount>> watchCounts(List<String> studentIds) =>
      roster.watchAccess().switchMap((access) {
        if (access == null || studentIds.isEmpty)
          return Stream.value(<String, YellowRibbonCount>{});
        final ids = studentIds.toSet().toList()..sort();
        final streams = <Stream<Map<String, YellowRibbonCount>>>[];
        // Wallet documents carry protected historical-site ACL metadata.
        // Keep query chunks bounded while sharing staff/config Rule lookups.
        for (var i = 0; i < ids.length; i += 8) {
          final chunk = ids.skip(i).take(8).toList();
          streams.add(firestore
              .collection('yellow_ribbon_counts')
              .where(FieldPath.documentId, whereIn: chunk)
              .snapshots()
              .withInitialResponseTimeout()
              .map((snapshot) {
            final found = {
              for (final doc in snapshot.docs)
                doc.id: YellowRibbonCount.fromFirestore(doc)
            };
            return {
              for (final sid in chunk)
                sid: found[sid] ?? YellowRibbonCount.create(sid)
            };
          }));
        }
        return streams.first.combineLatestAll(streams.skip(1)).map((all) => {
              for (final counts in all) ...counts,
            });
      });
  Future<void> redeem(String studentId, int amount, String operationId) =>
      roster.command({
        'action': 'redeemRibbon',
        'operationId': operationId,
        'studentId': studentId,
        'amount': amount,
      }).then((_) {});
  String newOperationId() => const Uuid().v4();
}
