import 'package:flutter/material.dart';

import '../../services/track_unlock_reason_service.dart';

/// A simple modal that explains how to unlock a learning track.
class TrackUnlockHintDialog extends StatelessWidget {
  final String message;

  const TrackUnlockHintDialog({super.key, required this.message});

  /// Shows the dialog for the given [trackId].
  static Future<void> show(BuildContext context, String trackId) async {
    final reason =
        await TrackUnlockReasonService.instance.getUnlockReason(trackId);
    if (reason == null) return;
    final match = RegExp("завершите трек '(.+)'", caseSensitive: false)
        .firstMatch(reason);
    final cta =
        match != null ? "Завершите '${match.group(1)}', чтобы открыть" : null;
    final message = cta == null ? reason : "$reason\n\n$cta";
    await showDialog<void>(
      context: context,
      builder: (_) => TrackUnlockHintDialog(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text('Трек заблокирован'),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
