import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/session_streak_overlay.dart';
import 'session_streak_tracker_service.dart';

/// Shows a temporary overlay banner with the current training session streak.
class SessionStreakOverlayPromptService {
  Future<void> run(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final streak = await SessionStreakTrackerService.instance.getCurrentStreak();
    if (streak <= 0) return;
    if (prefs.getBool('reward_10') ?? false) return;
    final overlay = Overlay.of(context);

    late OverlayEntry entry;
    void close() => entry.remove();
    entry = OverlayEntry(
      builder: (_) => SessionStreakOverlay(streak: streak, onDismiss: close),
    );
    overlay.insert(entry);
  }
}
