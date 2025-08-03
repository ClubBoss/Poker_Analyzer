import 'dart:async';
import 'package:poker_analyzer/services/preferences_service.dart';


import 'app_usage_tracker.dart';
import 'smart_theory_recap_engine.dart';
import 'tag_retention_tracker.dart';
import 'session_streak_tracker_service.dart';
import 'theory_recap_suppression_engine.dart';
import 'smart_theory_recap_dismissal_memory.dart';
import 'booster_fatigue_guard.dart';
import 'tag_mastery_service.dart';
import 'session_log_service.dart';
import 'training_session_service.dart';

/// Detects optimal moments to surface recap suggestions.
class RecapOpportunityDetector {
  final SmartTheoryRecapEngine engine;
  final TagRetentionTracker retention;
  final SessionStreakTrackerService streak;
  final AppUsageTracker usage;
  final TheoryRecapSuppressionEngine suppression;
  final SmartTheoryRecapDismissalMemory memory;
  final BoosterFatigueGuard fatigue;

  RecapOpportunityDetector({
    SmartTheoryRecapEngine? engine,
    required this.retention,
    SessionStreakTrackerService? streak,
    AppUsageTracker? usage,
    TheoryRecapSuppressionEngine? suppression,
    SmartTheoryRecapDismissalMemory? memory,
    BoosterFatigueGuard? fatigue,
  })  : engine = engine ?? SmartTheoryRecapEngine.instance,
        streak = streak ?? SessionStreakTrackerService.instance,
        usage = usage ?? AppUsageTracker.instance,
        suppression = suppression ?? TheoryRecapSuppressionEngine.instance,
        memory = memory ?? SmartTheoryRecapDismissalMemory.instance,
        fatigue = fatigue ?? BoosterFatigueGuard.instance;

  static final RecapOpportunityDetector instance = RecapOpportunityDetector(
    retention: TagRetentionTracker(
      mastery: TagMasteryService(logs: SessionLogService(sessions: TrainingSessionService())),
    ),
  );

  static const _lastKey = 'recap_detector_last';
  DateTime? _lastCompletion;
  Timer? _timer;

  Future<void> start({Duration interval = const Duration(minutes: 5)}) async {
    await usage.init();
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => _check());

  }
  void notifyDrillCompleted() {
    _lastCompletion = DateTime.now();
  }

  Future<void> dispose() async {
    await usage.dispose();
    _timer?.cancel();
  }

  Future<DateTime?> _lastPromptTime() async {
    final prefs = await PreferencesService.getInstance();
    final str = prefs.getString(_lastKey);
    return str == null ? null : DateTime.tryParse(str);
  }

  Future<void> _markPrompted() async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(_lastKey, DateTime.now().toIso8601String());
  }

  Future<void> _check() async {
    if (!await isGoodRecapMoment()) return;
    final tags = await retention.getDecayedTags();
    if (tags.isEmpty) return;
    final tag = tags.first;
    if (await memory.shouldThrottle('tag:$tag')) return;
    if (await suppression.getSuppressionReason(
          lessonId: '',
          trigger: 'opportunity',
        ) !=
        null) {
      return;
    }
    await engine.maybePrompt(tags: [tag], trigger: 'opportunity');
    await _markPrompted();
  }

  /// Returns true if conditions are favorable for showing a recap prompt.
  Future<bool> isGoodRecapMoment() async {
    final idle = await usage.idleDuration();
    if (idle < const Duration(minutes: 1)) return false;

    final recentCompletion = _lastCompletion != null &&
        DateTime.now().difference(_lastCompletion!) <
            const Duration(minutes: 10);
    if (!recentCompletion) {
      final last = await _lastPromptTime();
      if (last != null &&
          DateTime.now().difference(last) < const Duration(hours: 6)) {
        return false;
      }
    }

    if (await fatigue.isFatigued(trigger: 'opportunity')) return false;

    final tags = await retention.getDecayedTags();
    if (tags.isEmpty) return false;

    final streakCount = await streak.getCurrentStreak();
    return streakCount >= 3 || idle > const Duration(minutes: 5);
  }
}
