import 'dart:async';
import 'package:flutter/widgets.dart';

extension ContextExtensions on BuildContext {
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  Future<void> ifMounted(FutureOr<void> Function() fn) async {
    if (mounted) {
      await fn();
    }
  }
}
