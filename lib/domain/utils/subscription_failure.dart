import 'package:firebase_core/firebase_core.dart';

/// Only explicit authorization loss invalidates previously visible data.
/// Network, timeout and decoding failures leave the last valid snapshot intact.
class SubscriptionAccessDenied implements Exception {
  const SubscriptionAccessDenied();
}

bool clearsSubscriptionData(Object error) =>
    error is SubscriptionAccessDenied ||
    (error is FirebaseException &&
        const {'permission-denied', 'unauthenticated'}.contains(error.code));
