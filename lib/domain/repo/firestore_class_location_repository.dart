import 'package:cloud_firestore/cloud_firestore.dart';

import '../enum/class_location.dart';
import 'contracts/class_location_repository.dart';

/// `class_locations/{id}` = `{name: string, order: int}`.
class FirestoreClassLocationRepository implements ClassLocationRepository {
  FirestoreClassLocationRepository(this._firestore);
  final FirebaseFirestore _firestore;

  @override
  Stream<List<ClassLocation>> watch() => _firestore
      .collection('class_locations')
      .orderBy('order')
      .snapshots()
      .map((snapshot) => [
            for (final doc in snapshot.docs)
              ClassLocation(doc.data()['name'] as String)
          ]);
}
