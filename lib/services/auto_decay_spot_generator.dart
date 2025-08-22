import '../models/decay_tag_reinforcement_event.dart';
import '../models/v2/training_spot_v2.dart';
import 'decay_session_tag_impact_recorder.dart';
import 'mastery_persistence_service.dart';
import 'training_tag_performance_engine.dart';
import 'training_spot_library.dart';

class AutoDecaySpotGenerator {
  final Future<List<DecayTagReinforcementEvent>> Function(String tag) _history;
  final Future<Map<String, double>> Function() _mastery;
  final Future<Map<String, TagPerformance>> Function() _stats;
  final Future<List<TrainingSpotV2>> Function(String tag) _spotLoader;

  AutoDecaySpotGenerator({
    Future<List<DecayTagReinforcementEvent>> Function(String tag)? historyLoader,
    Future<Map<String, double>> Function()? masteryLoader,
    Future<Map<String, TagPerformance>> Function()? statsLoader,
    Future<List<TrainingSpotV2>> Function(String tag)? spotLoader,
  })  : _history = historyLoader ??
            DecaySessionTagImpactRecorder.instance.getRecentReinforcements,
        _mastery = masteryLoader ?? MasteryPersistenceService().load,
        _stats = statsLoader ??
            () => TrainingTagPerformanceEngine.computeTagStats(),
        final _spotLoader = spotLoader ?? TrainingSpotLibrary().indexByTag;

  Future<List<TrainingSpotV2>> generate({
    int limit = 10,
    Iterable<String>? tagScope,
    Duration minDecay = const Duration(days: 30),
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final masteryMap = await _mastery();
    final statsMap = await _stats();

    final tags = tagScope != null
        ? {for (final t in tagScope) t.trim().toLowerCase()}
        : masteryMap.keys.toSet();

    final candidates = <_TagCandidate>[];
    for (final tag in tags) {
      if (tag.isEmpty) continue;
      final events = await _history(tag);
      final last = events.isNotEmpty ? events.first.timestamp : null;
      final days = last != null
          ? current.difference(last).inDays.toDouble()
          : 9999.0;
      if (days < minDecay.inDays) continue;
      final mastery = masteryMap[tag] ?? 0.5;
      final perf = statsMap[tag];
      final mistake = perf != null && perf.totalAttempts > 0
          ? 1 - perf.accuracy
          : 0.0;
      if (mastery >= 0.6 && mistake <= 0.25) continue;
      final score = (days / minDecay.inDays) +
          (mastery < 0.6 ? (0.6 - mastery) : 0) +
          (mistake > 0.25 ? (mistake - 0.25) : 0);
      candidates.add(_TagCandidate(tag: tag, score: score));
    }

    if (candidates.isEmpty) return [];
    candidates.sort((a, b) => b.score.compareTo(a.score));

    final scoredSpots = <_ScoredSpot>[];
    final used = <String>{};

    for (final cand in candidates) {
      if (scoredSpots.length >= limit) break;
      final spots = await _spotLoader(cand.tag);
      if (spots.isEmpty) continue;
      spots.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      var added = 0;
      for (final spot in spots) {
        if (used.add(spot.id)) {
          scoredSpots.add(_ScoredSpot(spot: spot, score: cand.score));
          added++;
          if (added >= 2 || scoredSpots.length >= limit) break;
        }
      }
    }

    scoredSpots.sort((a, b) => b.score.compareTo(a.score));
    return [for (final s in scoredSpots.take(limit)) s.spot];
  }
}

class _TagCandidate {
  final String tag;
  final double score;
  const _TagCandidate({required this.tag, required this.score});
}

class _ScoredSpot {
  final TrainingSpotV2 spot;
  final double score;
  const _ScoredSpot({required this.spot, required this.score});
}
