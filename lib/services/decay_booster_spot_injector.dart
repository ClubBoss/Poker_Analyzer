import '../models/v2/training_spot_v2.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/training_history_entry_v2.dart';
import '../core/training/library/training_pack_library_v2.dart';
import 'booster_queue_service.dart';
import 'mini_lesson_library_service.dart';
import 'theory_tag_decay_tracker.dart';
import 'training_history_service_v2.dart';

/// Injects practice spots for highly decayed tags into the booster queue.
class DecayBoosterSpotInjector {
  final TheoryTagDecayTracker decay;
  final MiniLessonLibraryService lessons;
  final BoosterQueueService queue;
  final TrainingPackLibraryV2 library;
  final Future<List<TrainingHistoryEntryV2>> Function({int limit})
  _historyLoader;

  DecayBoosterSpotInjector({
    TheoryTagDecayTracker? decay,
    MiniLessonLibraryService? lessons,
    BoosterQueueService? queue,
    TrainingPackLibraryV2? library,
    Future<List<TrainingHistoryEntryV2>> Function({int limit})? historyLoader,
  }) : decay = decay ?? TheoryTagDecayTracker(),
       lessons = lessons ?? MiniLessonLibraryService.instance,
       queue = queue ?? BoosterQueueService.instance,
       library = library ?? TrainingPackLibraryV2.instance,
       _historyLoader = historyLoader ?? TrainingHistoryServiceV2.getHistory;

  static final DecayBoosterSpotInjector instance = DecayBoosterSpotInjector();

  /// Schedules spots for decayed tags into the booster queue.
  Future<void> inject({DateTime? now}) async {
    final scores = await decay.computeDecayScores(now: now);
    final entries = scores.entries.where((e) => e.value > 50).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return;

    await library.loadFromFolder();
    await lessons.loadAll();
    final history = await _historyLoader(limit: 20);
    final recentPacks = {for (final h in history) h.packId};

    final spots = <TrainingSpotV2>[];
    final used = <String>{};

    for (final entry in entries) {
      final tag = entry.key.trim().toLowerCase();
      if (tag.isEmpty) continue;
      var added = 0;

      // Look in recent packs first.
      for (final id in recentPacks) {
        final pack = library.getById(id);
        if (pack == null) continue;
        added += _collectSpots(pack, tag, spots, used, max: 2 - added);
        if (added >= 2) break;
      }

      // Fallback to packs linked via mini lessons.
      if (added == 0) {
        final lessonList = lessons.findByTags([tag]);
        for (final lesson in lessonList) {
          for (final pid in lesson.linkedPackIds) {
            final pack = library.getById(pid);
            if (pack == null) continue;
            added += _collectSpots(pack, tag, spots, used, max: 2 - added);
            if (added >= 2) break;
          }
          if (added >= 2) break;
        }
      }
    }

    if (spots.isNotEmpty) {
      await queue.addSpots(spots);
    }
  }

  int _collectSpots(
    TrainingPackTemplateV2 pack,
    String tag,
    List<TrainingSpotV2> out,
    Set<String> used, {
    int max = 2,
  }) {
    var added = 0;
    for (final spot in pack.spots) {
      final tags = spot.tags.map((t) => t.trim().toLowerCase());
      if (tags.contains(tag) && used.add(spot.id)) {
        out.add(spot);
        added++;
        if (added >= max) break;
      }
    }
    return added;
  }
}
