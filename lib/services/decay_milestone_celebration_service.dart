import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../widgets/confetti_overlay.dart';
import 'coins_service.dart';
import 'decay_streak_tracker_service.dart';

/// Shows a small celebration when the decay streak hits key milestones.
class DecayMilestoneCelebrationService {
  final DecayStreakTrackerService tracker;
  final CoinsService coins;

  DecayMilestoneCelebrationService({
    DecayStreakTrackerService? tracker,
    CoinsService? coins,
  })  : tracker = tracker ?? const DecayStreakTrackerService(),
        coins = coins ?? CoinsService.instance;

  static const _prefsKey = 'decay_milestone_last';
  static const _milestones = [3, 7, 14, 30];
  static const _coinBonus = 10;

  Path _starPath(Size size) {
    const points = 5;
    final halfWidth = size.width / 2;
    final external = halfWidth;
    final internal = halfWidth / 2.5;
    final center = Offset(halfWidth, halfWidth);
    final path = Path();
    const step = math.pi / points;
    for (int i = 0; i < points * 2; i++) {
      final radius = i.isEven ? external : internal;
      final angle = step * i;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  /// Checks the current streak and celebrates newly reached milestones.
  Future<void> maybeCelebrate(BuildContext context) async {
    final prefs = await PreferencesService.getInstance();
    final last = prefs.getInt(_prefsKey) ?? 0;
    final streak = await tracker.getCurrentStreak();
    int? milestone;
    for (final m in _milestones) {
      if (streak >= m && m > last) {
        milestone = m;
        break;
      }
    }
    if (milestone == null) return;

    await prefs.setInt(_prefsKey, milestone);
    showConfettiOverlay(context, particlePath: _starPath);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '🧠 Your focus is paying off — $milestone days without decay!',
        ),
      ),
    );
    unawaited(coins.addCoins(_coinBonus));
  }
}
