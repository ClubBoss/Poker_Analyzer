import 'package:flutter/material.dart';

import '../main.dart';

/// Simple helper to display lightweight in-app nudges.
class InAppNudgeService {
  /// Shows a snackbar style nudge with [title] and [message].
  /// Returns `true` if displayed, otherwise `false`.
  static Future<bool> show({
    required String title,
    required String message,
    VoidCallback? onTap,
  }) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return false;
    final messenger = ScaffoldMessenger.maybeOf(ctx);
    if (messenger == null) return false;
    messenger.showSnackBar(
      SnackBar(
        content: Text('$title\n$message'),
        action: onTap != null
            ? SnackBarAction(label: 'Open', onPressed: onTap)
            : null,
      ),
    );
    return true;
  }
}
