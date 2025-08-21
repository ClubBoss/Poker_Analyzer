import '../models/v2/training_spot_v2.dart';
import 'auto_decay_spot_generator.dart';
import 'recent_spot_history_service.dart';

/// Builds a queue of practice spots boosted by decay urgency.
class DecayBoostedPracticeQueue {
  final AutoDecaySpotGenerator generator;
  final RecentSpotHistoryService history;

  DecayBoostedPracticeQueue({
    AutoDecaySpotGenerator? generator,
    RecentSpotHistoryService? history,
  })  : generator = generator ?? const AutoDecaySpotGenerator(),
        history = history ?? RecentSpotHistoryService.instance;

  /// Generates up to 5 spots prioritized by decay and filtered against
  /// the most recent session.
  Future<List<TrainingSpotV2>> prepareQueue({int limit = 5}) async {
    if (limit <= 0) return <TrainingSpotV2>[];
    final spots = await generator.generate(limit: limit);
    if (spots.isEmpty) return <TrainingSpotV2>[];
    final recentIds = await history.load();
    final filtered = <TrainingSpotV2>[];
    for (final s in spots) {
      if (!recentIds.contains(s.id)) {
        final spot = TrainingSpotV2.fromJson(s.toJson());
        spot.meta['origin'] = 'decayBoost';
        filtered.add(spot);
        if (filtered.length >= 5) break;
      }
    }
    if (filtered.length > 5) filtered.length = 5;
    if (filtered.length < 3) return filtered;
    return filtered;
  }
}
