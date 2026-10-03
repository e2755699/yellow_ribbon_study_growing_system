import 'package:cloud_firestore/cloud_firestore.dart';
import 'roster_commands.dart';
import '../utils/request_timeout.dart';

class FirebaseRosterCommandStore implements RosterCommandStore {
  final FirebaseFirestore firestore;
  FirebaseRosterCommandStore(this.firestore);
  @override
  Future<T> transaction<T>(Future<T> Function(RosterCommandTransaction) body) =>
      firestore
          .runTransaction((tx) => body(_Transaction(firestore, tx)),
              timeout: requestTimeout)
          .withRequestTimeout();
  @override
  Object get serverTimestamp => FieldValue.serverTimestamp();
  @override
  Object timestamp(DateTime value) => Timestamp.fromDate(value);
  @override
  DateTime? dateTime(Object? value) =>
      value is Timestamp ? value.toDate() : null;
}

class _Transaction implements RosterCommandTransaction {
  final FirebaseFirestore firestore;
  final Transaction transaction;
  _Transaction(this.firestore, this.transaction);
  @override
  Future<RosterMap?> get(String path) async =>
      (await transaction.get(firestore.doc(path))).data();
  @override
  void set(String path, RosterMap data, {bool merge = false}) =>
      transaction.set(firestore.doc(path), data, SetOptions(merge: merge));
}
