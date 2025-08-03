import 'package:flutter/material.dart';

import '../../screens/lesson_path_screen.dart';
import '../../services/track_unlock_reason_service.dart';
import '../../services/shared_preferences_service.dart';

/// A simple modal that explains how to unlock a learning track.
class TrackUnlockHintDialog extends StatelessWidget {
  final String message;
  final String? prerequisiteId;
  final String? prerequisiteTitle;

  const TrackUnlockHintDialog({
    super.key,
    required this.message,
    this.prerequisiteId,
    this.prerequisiteTitle,
  });

  /// Shows the dialog for the given [trackId].
  static Future<void> show(BuildContext context, String trackId) async {
    final reasonService = TrackUnlockReasonService.instance;
    final reason = await reasonService.getUnlockReason(trackId);
    if (reason == null) return;
    final prereqId = reasonService.lockEvaluator.prerequisites[trackId];
    String? prereqTitle;
    if (prereqId != null) {
      prereqTitle =
          reasonService.trackEngine.getTrackById(prereqId)?.title ?? prereqId;
    }
    final match =
        RegExp("завершите трек '(.+)'", caseSensitive: false).firstMatch(reason);
    final cta =
        match != null ? "Завершите '${match.group(1)}', чтобы открыть" : null;
    final message = cta == null ? reason : "$reason\n\n$cta";
    await showDialog<void>(
      context: context,
      builder: (_) => TrackUnlockHintDialog(
        message: message,
        prerequisiteId: prereqId,
        prerequisiteTitle: prereqTitle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text('Трек заблокирован'),
      content: Text(message),
      actions: [
        if (prerequisiteId != null && prerequisiteTitle != null)
          TextButton(
            onPressed: () async {
              await SharedPreferencesService.instance.init();
              final prefs = SharedPreferencesService.instance;
              await prefs.setString(
                  'lesson_selected_track', prerequisiteId!);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const LessonPathScreen(),
                ),
              );
            },
            child:
                Text("Перейти к треку '$prerequisiteTitle'"),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
