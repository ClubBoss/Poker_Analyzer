import 'dart:async';
import 'package:flutter/widgets.dart';

extension ContextExtensions on BuildContext {
  Future<void> ifMounted(FutureOr<void> Function() fn) async {
    if (mounted) {
      await fn();
    }
  }
}
