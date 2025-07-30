import '../models/theory_recap_prompt_event.dart';
import 'theory_recap_trigger_logger.dart';
import 'theory_recap_analytics_reporter.dart';

/// Detects repeated dismissal of recap prompts to avoid overprompting.
class BoosterFatigueGuard {
  final Future<List<TheoryRecapPromptEvent>> Function({int limit}) _loader;

  BoosterFatigueGuard({
    Future<List<TheoryRecapPromptEvent>> Function({int limit})? loader,
  }) : _loader = loader ?? TheoryRecapTriggerLogger.getRecentEvents;

  static final BoosterFatigueGuard instance = BoosterFatigueGuard();

  /// Returns true if the user recently dismissed multiple recap prompts.
  Future<bool> isFatigued({String lessonId = '', String trigger = ''}) async {
    final events = await _loader(limit: 10);
    int dismisses = 0;
    int streak = 0;
    for (final e in events) {
      final dismissed = e.outcome == 'dismissed';
      if (dismissed) {
        dismisses++;
        streak++;
        if (streak >= 2) {
          await TheoryRecapAnalyticsReporter.instance.logEvent(
            lessonId: lessonId,
            trigger: trigger,
            outcome: 'fatigued',
            delay: null,
          );
          return true;
        }
      } else {
        streak = 0;
      }
    }
    if (dismisses >= 3) {
      await TheoryRecapAnalyticsReporter.instance.logEvent(
        lessonId: lessonId,
        trigger: trigger,
        outcome: 'fatigued',
        delay: null,
      );
      return true;
    }
    return false;
  }
}
