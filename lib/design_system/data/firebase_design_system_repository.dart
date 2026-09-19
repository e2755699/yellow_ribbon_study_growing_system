import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/design_system_repository.dart';
import '../domain/theme_definition.dart';

class FirebaseDesignSystemRepository implements DesignSystemRepository {
  FirebaseDesignSystemRepository(this.firestore, this.auth);
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;
  static const collectionPath = 'design_systems/yellow_ribbon/themes';

  @override
  Future<bool> canPublish() async {
    final user = auth.currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult();
    return token.claims?['designSystemAdmin'] == true;
  }

  @override
  Stream<List<ThemeDefinition>> watchThemes() {
    late StreamController<List<ThemeDefinition>> output;
    StreamSubscription<User?>? users;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? documents;
    var generation = 0;
    output = StreamController(onListen: () {
      users = auth.idTokenChanges().listen((user) async {
        final request = ++generation;
        await documents?.cancel();
        if (output.isClosed || request != generation) return;
        if (user == null) {
          output.add([]);
          return;
        }
        documents =
            firestore.collection(collectionPath).snapshots().listen((snapshot) {
          if (output.isClosed || request != generation) return;
          try {
            output.add(snapshot.docs
                .map((doc) => ThemeDefinition.fromJson(doc.id, doc.data()))
                .toList());
          } catch (error, stack) {
            output.addError(error, stack);
          }
        }, onError: (Object error, StackTrace stack) {
          if (!output.isClosed && request == generation) {
            output.addError(error, stack);
          }
        });
      }, onError: output.addError);
    }, onCancel: () async {
      generation++;
      await users?.cancel();
      await documents?.cancel();
    });
    return output.stream;
  }

  @override
  Future<ThemeDefinition> publish(ThemeDefinition theme,
      {required int expectedRevision}) async {
    if (!await canPublish()) throw const ThemePermissionDenied();
    final errors = theme.validationErrors;
    if (errors.isNotEmpty) throw FormatException(errors.join('；'));
    final uid = auth.currentUser?.uid;
    if (uid == null) throw const ThemePermissionDenied();
    final reference = firestore.collection(collectionPath).doc(theme.id);
    return firestore.runTransaction((transaction) async {
      final current = await transaction.get(reference);
      final revision = current.data()?['revision'] ?? 0;
      if (revision != expectedRevision) throw const ThemeConflict();
      final saved = theme.copyWith(revision: expectedRevision + 1);
      transaction.set(reference, {
        ...saved.toJson(),
        'updatedBy': uid,
        'updatedAt': FieldValue.serverTimestamp()
      });
      return saved;
    });
  }
}
