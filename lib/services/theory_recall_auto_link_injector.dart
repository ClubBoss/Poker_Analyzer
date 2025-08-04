import '../models/v2/training_pack_spot.dart';
import '../services/decay_tag_retention_tracker_service.dart';
import '../services/inline_theory_linker_service.dart';
import '../services/theory_mini_lesson_usage_tracker.dart';
import '../models/theory_mini_lesson_usage_event.dart';

/// Injects dynamic theory lesson links into decayed review spots.
class TheoryRecallAutoLinkInjector {
  final DecayTagRetentionTrackerService retention;
  final InlineTheoryLinkerService linker;
  final TheoryMiniLessonUsageTracker usageTracker;

  TheoryRecallAutoLinkInjector({
    DecayTagRetentionTrackerService? retention,
    InlineTheoryLinkerService? linker,
    TheoryMiniLessonUsageTracker? usageTracker,
  }) : retention = retention ?? const DecayTagRetentionTrackerService(),
       linker = linker ?? InlineTheoryLinkerService(),
       usageTracker = usageTracker ?? TheoryMiniLessonUsageTracker.instance;

  /// Attaches a [`linkedTheoryId`] to [spot] when its tags are decayed and
  /// the corresponding lesson hasn't been opened manually before.
  Future<TrainingPackSpot> inject(TrainingPackSpot spot) async {
    if (!await _hasDecayedTag(spot)) return spot;

    final ids = await linker.getLinkedLessonIdsForSpot(spot);
    if (ids.isEmpty) return spot;
    final lessonId = ids.first;

    final logs = await usageTracker.getRecent(limit: 200);
    if (logs.any((e) => e.lessonId == lessonId)) return spot;

    spot.meta['linkedTheoryId'] = lessonId;
    return spot;
  }

  /// Convenience method to inject links for multiple [spots].
  Future<void> injectAll(Iterable<TrainingPackSpot> spots) async {
    for (final s in spots) {
      await inject(s);
    }
  }

  Future<bool> _hasDecayedTag(TrainingPackSpot spot) async {
    for (final t in spot.tags) {
      if (await retention.isDecayed(t)) return true;
    }
    return false;
  }
}
