import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/booster_backlink.dart';
import '../models/training_pack.dart';
import '../models/v2/training_pack_template.dart';
import '../models/drill_result.dart';
import 'smart_theory_recap_engine.dart';
import 'theory_boost_recap_linker.dart';
import 'theory_recap_review_tracker.dart';
import '../models/theory_recap_review_entry.dart';
import 'theory_recap_suppression_engine.dart';
import 'theory_booster_recap_delay_manager.dart';
import 'booster_fatigue_guard.dart';
import 'theory_recap_analytics_reporter.dart';
import 'smart_booster_dropoff_detector.dart';
import 'smart_theory_recap_dismissal_memory.dart';

/// Listens to booster and drill results and triggers theory recap when needed.
class BoosterRecapHook {
  final SmartTheoryRecapEngine engine;
  final TheoryRecapSuppressionEngine suppression;
  final TheoryRecapAnalyticsReporter analytics;
  final SmartBoosterDropoffDetector dropoff;
  final SmartTheoryRecapDismissalMemory memory;
  BoosterRecapHook({
    SmartTheoryRecapEngine? engine,
    TheoryRecapSuppressionEngine? suppression,
    TheoryRecapAnalyticsReporter? analytics,
    SmartBoosterDropoffDetector? dropoff,
    SmartTheoryRecapDismissalMemory? memory,
  })  : engine = engine ?? SmartTheoryRecapEngine.instance,
        suppression = suppression ?? TheoryRecapSuppressionEngine.instance,
        analytics = analytics ?? TheoryRecapAnalyticsReporter.instance,
        dropoff = dropoff ?? SmartBoosterDropoffDetector.instance,
        memory = memory ?? SmartTheoryRecapDismissalMemory.instance;

  static final BoosterRecapHook instance = BoosterRecapHook();

  static const _reviewPrefix = 'review_count_';
  final Map<String, int> _reviewCache = {};

  Future<Duration?> _delayForKeys(List<String> keys) async {
    DateTime? last;
    for (final k in keys) {
      final ts = await TheoryBoosterRecapDelayManager.lastPromptTime(k);
      if (ts != null && (last == null || ts.isAfter(last))) {
        last = ts;
      }
    }
    return last == null ? null : DateTime.now().difference(last);
  }

  Future<int> _incrementReview(String id) async {
    if (id.isEmpty) return 0;
    final prefs = await SharedPreferences.getInstance();
    final key = '$_reviewPrefix$id';
    final count = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, count);
    _reviewCache[id] = count;
    return count;
  }

  /// Call when a hand review screen is opened.
  Future<void> onReviewOpened({
    required String handId,
    List<String>? tags,
  }) async {
    final count = await _incrementReview(handId);
    if (count > 1) {
      const trigger = 'review';
      if (await BoosterFatigueGuard.instance
          .isFatigued(lessonId: '', trigger: trigger)) {
        await analytics.logEvent(
          lessonId: '',
          trigger: trigger,
          outcome: 'fatigued',
          delay: null,
        );
        return;
      }
      if (tags != null) {
        for (final t in tags) {
          if (await memory.shouldThrottle('tag:$t')) {
            await analytics.logEvent(
              lessonId: '',
              trigger: trigger,
              outcome: 'cooldown',
              delay: null,
            );
            return;
          }
        }
      }
      await engine.maybePrompt(tags: tags, trigger: trigger);
    }
  }

  /// Call when a drill result screen is shown.
  Future<void> onDrillResult({
    required int mistakes,
    List<String>? tags,
  }) async {
    if (mistakes >= 2) {
      const trigger = 'drillResult';
      if (await BoosterFatigueGuard.instance
          .isFatigued(lessonId: '', trigger: trigger)) {
        await analytics.logEvent(
          lessonId: '',
          trigger: trigger,
          outcome: 'fatigued',
          delay: null,
        );
        return;
      }
      if (tags != null) {
        for (final t in tags) {
          if (await memory.shouldThrottle('tag:$t')) {
            await analytics.logEvent(
              lessonId: '',
              trigger: trigger,
              outcome: 'cooldown',
              delay: null,
            );
            return;
          }
        }
      }
      await engine.maybePrompt(tags: tags, trigger: trigger);
    }
  }

  /// Call when a booster recap screen is shown.
  Future<void> onBoosterResult({
    required TrainingSessionResult result,
    required TrainingPackTemplateV2 booster,
    BoosterBacklink? backlink,
  }) async {
    final total = result.total;
    final correct = result.correct;
    final failed = total > 0 && correct / total < 0.5;
    await dropoff.recordOutcome(failed ? 'failed' : 'completed');
    if (!failed) return;
    const trigger = 'boosterFailure';
    if (await BoosterFatigueGuard.instance
        .isFatigued(lessonId: '', trigger: trigger)) {
      await analytics.logEvent(
        lessonId: '',
        trigger: trigger,
        outcome: 'fatigued',
        delay: null,
      );
      return;
    }
    String? lessonId;
    List<String>? tags = booster.tags;
    if (backlink != null) {
      tags = backlink.matchingTags.toList();
      if (backlink.relatedLessonIds.isNotEmpty) {
        lessonId = backlink.relatedLessonIds.first;
      }
    }
    lessonId ??= tags.isNotEmpty
        ? const TheoryBoostRecapLinker().getLinkedLesson(tags.first)
        : null;
    final keys = <String>[];
    if (lessonId != null) {
      keys.add('lesson:$lessonId');
    } else {
      keys.addAll(tags.map((t) => 'tag:$t'));
    }

    for (final k in keys) {
      if (await memory.shouldThrottle(k)) {
        await analytics.logEvent(
          lessonId: lessonId ?? '',
          trigger: trigger,
          outcome: 'cooldown',
          delay: await _delayForKeys(keys),
        );
        return;
      }
    }
    for (final k in keys) {
      if (await TheoryBoosterRecapDelayManager.isUnderCooldown(
        k,
        const Duration(hours: 24),
      )) {
        return;
      }
    }
    if (await dropoff.isInDropoffState()) {
      await analytics.logEvent(
        lessonId: lessonId ?? '',
        trigger: trigger,
        outcome: 'dropoff',
        delay: await _delayForKeys(keys),
      );
      return;
    }
    if (lessonId != null &&
        await suppression.shouldSuppress(
          lessonId: lessonId,
          trigger: 'boosterFailure',
        )) {
      await analytics.logEvent(
        lessonId: lessonId,
        trigger: trigger,
        outcome: 'suppressed',
        delay: await _delayForKeys(keys),
      );
      return;
    }
    await engine.maybePrompt(
      lessonId: lessonId,
      tags: tags,
      trigger: trigger,
    );
    for (final k in keys) {
      unawaited(TheoryBoosterRecapDelayManager.markPrompted(k));
    }
    await analytics.logEvent(
      lessonId: lessonId ?? '',
      trigger: trigger,
      outcome: 'shown',
      delay: await _delayForKeys(keys),
    );
    await TheoryRecapReviewTracker.instance.log(
      TheoryRecapReviewEntry(
        lessonId: lessonId ?? '',
        trigger: 'boosterFailure',
        timestamp: DateTime.now(),
      ),
    );
  }
}
