import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../widgets/confetti_overlay.dart';
import 'xp_level_engine.dart';
import 'xp_reward_engine.dart';
import '../main.dart';

/// Triggers a celebration animation when the user levels up.
class LevelUpCelebrationEngine {
  LevelUpCelebrationEngine._();

  /// Singleton instance.
  static final LevelUpCelebrationEngine instance = LevelUpCelebrationEngine._();

  static const _prefsKey = 'level_up_last';
  static const int _bonusXp = 25;

  /// Checks if XP increased enough to reach a new level and shows celebration.
  Future<void> checkAndCelebrate(int oldXp, int newXp) async {
    final oldLevel = XPLevelEngine.instance.getLevel(oldXp);
    final newLevel = XPLevelEngine.instance.getLevel(newXp);
    if (newLevel <= oldLevel) return;

    final prefs = await PreferencesService.getInstance();
    final last = prefs.getInt(_prefsKey) ?? 0;
    if (newLevel <= last) return;

    await prefs.setInt(_prefsKey, newLevel);
    unawaited(XPRewardEngine.instance.addXp(_bonusXp));
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      showConfettiOverlay(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('🎉 Уровень $newLevel! +$_bonusXp XP')),
      );
      unawaited(SystemSound.play(SystemSoundType.alert));
    }
  }
}
