import 'package:flutter/material.dart';

import '../widgets/streak_milestone_celebration_overlay.dart';

/// Queues streak milestone celebrations to avoid overlapping animations.
class StreakMilestoneQueueService {
  StreakMilestoneQueueService._();

  /// Singleton instance.
  static final StreakMilestoneQueueService instance =
      StreakMilestoneQueueService._();

  final List<int> _queue = [];
  bool _showing = false;

  /// Add a milestone [streakDays] to the celebration queue.
  void addMilestoneToQueue(int streakDays) {
    _queue.add(streakDays);
  }

  /// Displays the next milestone celebration if any are queued.
  Future<void> showNextMilestoneCelebrationIfAny(BuildContext context) async {
    if (_showing || _queue.isEmpty || !context.mounted) return;
    _showing = true;
    final days = _queue.removeAt(0);
    final msg = '🔥 Поздравляем! Ты достиг $days-дневного стрика! 🎉';
    await showCelebrationOverlay(context, msg);
    _showing = false;
    if (_queue.isNotEmpty) {
      await showNextMilestoneCelebrationIfAny(context);
    }
  }
}
