import 'package:flutter/material.dart';
import 'package:poker_analyzer/services/preferences_service.dart';

import '../services/session_log_service.dart';
import '../widgets/skill_loss_overlay_prompt.dart';

/// Checks inactivity and performance to occasionally show [SkillLossOverlayPrompt].
class SkillLossOverlayPromptService {
  SkillLossOverlayPromptService({required this.logs});

  final SessionLogService logs;

  static const _lastKey = 'skill_loss_overlay_prompt_last';
  static const _gap = Duration(days: 5);

  Future<void> run(BuildContext context) async {
    final prefs = await PreferencesService.getInstance();
    final now = DateTime.now();
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    if (last != null && now.difference(last) < const Duration(days: 1)) {
      return;
    }

    await logs.load();
    DateTime? lastTraining;
    if (logs.logs.isNotEmpty) {
      lastTraining = logs.logs.first.completedAt;
    }

    var show = false;
    if (lastTraining == null || now.difference(lastTraining) > _gap) {
      show = true;
    } else {
      final recent = logs.logs.take(3).toList();
      if (recent.length >= 3) {
        var correct = 0;
        var total = 0;
        for (final l in recent) {
          correct += l.correctCount;
          total += l.correctCount + l.mistakeCount;
        }
        if (total >= 3 && correct / total < 0.5) {
          show = true;
        }
      }
    }

    if (!show) return;
    await prefs.setString(_lastKey, now.toIso8601String());
    if (context.mounted) {
      await SkillLossOverlayPrompt.show(context);
    }
  }
}
