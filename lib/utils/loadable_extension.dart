import 'dart:async';

extension LoadableExtension on Object {
  Future<void> init() {
    final dynamic service = this;
    final result = service.load();
    if (result is Future) {
      return result as Future<void>;
    }
    return Future.value();
  }
}
