import 'package:flutter/material.dart';

import '../main.dart';

/// Simple wrapper around the global [navigatorKey].
class NavigationService {
  NavigationService();

  /// Current navigator context if available.
  BuildContext? get context => navigatorKey.currentContext;

  /// Pushes [route] using the root navigator.
  Future<T?> push<T>(Route<T> route) async {
    final state = navigatorKey.currentState;
    if (state == null) return null;
    return state.push(route);
  }
}
