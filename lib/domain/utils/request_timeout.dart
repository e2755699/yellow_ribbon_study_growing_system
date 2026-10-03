import 'dart:async';

/// App-owned network operations share one deadline. A Future timeout stops
/// waiting; it does not prove that a remote write was cancelled or rejected.
const requestTimeout = Duration(seconds: 60);

class RequestTimeoutException extends TimeoutException {
  RequestTimeoutException()
      : super('連線逾時（60 秒），尚未取得伺服器確認，請檢查網路後重試。', requestTimeout);
}

extension RequestDeadline<T> on Future<T> {
  Future<T> withRequestTimeout() =>
      timeout(requestTimeout, onTimeout: () => throw RequestTimeoutException());
}

extension InitialResponseDeadline<T> on Stream<T> {
  /// Only the initial response has a deadline. An idle live subscription is
  /// healthy; after timeout it may still recover when the source sends data.
  Stream<T> withInitialResponseTimeout({bool Function(T)? isReady}) =>
      Stream.multi((out) {
        var received = false;
        final timer = Timer(requestTimeout, () {
          if (!received) {
            received = true;
            out.addError(RequestTimeoutException());
          }
        });
        final subscription = listen((value) {
          if (isReady == null || isReady(value)) {
            received = true;
            timer.cancel();
          }
          out.add(value);
        }, onError: (Object error, StackTrace stack) {
          received = true;
          timer.cancel();
          out.addError(error, stack);
        }, onDone: () {
          timer.cancel();
          if (!received) out.addError(StateError('連線已結束，未取得資料，請重試。'));
          out.close();
        });
        out.onPause = subscription.pause;
        out.onResume = subscription.resume;
        out.onCancel = () {
          timer.cancel();
          return subscription.cancel();
        };
      });
}
