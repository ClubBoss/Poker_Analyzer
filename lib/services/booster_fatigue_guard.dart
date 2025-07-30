import '../models/theory_recap_prompt_event.dart';
import 'theory_recap_trigger_logger.dart';

/// Detects repeated dismissal of recap prompts to avoid overprompting.
class BoosterFatigueGuard {
  final Future<List<TheoryRecapPromptEvent>> Function({int limit}) _loader;

  BoosterFatigueGuard({
    Future<List<TheoryRecapPromptEvent>> Function({int limit})? loader,
  }) : _loader = loader ?? TheoryRecapTriggerLogger.getRecentEvents;

  static final BoosterFatigueGuard instance = BoosterFatigueGuard();

  /// Returns true if the user recently dismissed multiple recap prompts.
  Future<bool> isFatigued() async {
    final events = await _loader(limit: 10);
    int dismisses = 0;
    int streak = 0;
    for (final e in events) {
      final dismissed = e.outcome == 'dismissed';
      if (dismissed) {
        dismisses++;
        streak++;
        if (streak >= 2) return true;
      } else {
        streak = 0;
      }
    }
    return dismisses >= 3;
  }
}
