import '../models/v2/training_spot_v2.dart';
import 'decay_topic_suppressor_service.dart';
import 'theory_tag_decay_tracker.dart';
import 'training_spot_library.dart';
import 'booster_queue_service.dart';

/// Suggests training spots for highly decayed theory tags.
class DecaySpotBoosterEngine {
  final TheoryTagDecayTracker decay;
  final DecayTopicSuppressorService suppressor;
  final TrainingSpotLibrary library;
  final BoosterQueueService queue;

  DecaySpotBoosterEngine({
    TheoryTagDecayTracker? decay,
    DecayTopicSuppressorService? suppressor,
    TrainingSpotLibrary? library,
    BoosterQueueService? queue,
  })  : decay = decay ?? TheoryTagDecayTracker(),
        suppressor = suppressor ?? DecayTopicSuppressorService.instance,
        library = library ?? TrainingSpotLibrary(),
        queue = queue ?? BoosterQueueService.instance;

  /// Queues practical drills for decayed tags.
  Future<void> enqueueDecayBoosters() async {
    final scores = await decay.computeDecayScores();
    final entries = scores.entries.where((e) => e.value > 50).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final spots = <TrainingSpotV2>[];

    for (final e in entries) {
      final tag = e.key;
      if (await suppressor.shouldSuppress(tag)) continue;
      final list = await library.indexByTag(tag);
      if (list.isEmpty) continue;
      final seen = <String>{};
      for (final spot in list) {
        final key = '${spot.hand.position}_${spot.hand.stacks['0']}';
        if (seen.add(key)) {
          spots.add(spot);
        }
        if (seen.length >= 3) break;
      }
    }

    if (spots.isNotEmpty) {
      await queue.addSpots(spots);
    }
  }

  /// Queues practice spots related to a single [tag].
  Future<void> enqueueForTag(String tag) async {
    final lc = tag.trim().toLowerCase();
    if (lc.isEmpty) return;
    if (await suppressor.shouldSuppress(lc)) return;
    final list = await library.indexByTag(lc);
    if (list.isEmpty) return;
    final spots = <TrainingSpotV2>[];
    final seen = <String>{};
    for (final spot in list) {
      final key = '${spot.hand.position}_${spot.hand.stacks['0']}';
      if (seen.add(key)) {
        spots.add(spot);
      }
      if (seen.length >= 3) break;
    }
    if (spots.isNotEmpty) {
      await queue.addSpots(spots);
    }
  }
}
