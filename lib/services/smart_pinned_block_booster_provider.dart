import 'pinned_block_tracker_service.dart';
import 'theory_block_library_service.dart';
import 'decay_recall_evaluator_service.dart';

/// Suggests booster drills for pinned blocks with decayed tags.
class PinnedBlockBoosterSuggestion {
  final String blockId;
  final String blockTitle;
  final String tag;
  final String action; // 'resumePack' or 'reviewTheory'
  final String? packId;

  const PinnedBlockBoosterSuggestion({
    required this.blockId,
    required this.blockTitle,
    required this.tag,
    required this.action,
    this.packId,
  });
}

class SmartPinnedBlockBoosterProvider {
  SmartPinnedBlockBoosterProvider({
    PinnedBlockTrackerService? tracker,
    TheoryBlockLibraryService? library,
    DecayRecallEvaluatorService? evaluator,
  }) : tracker = tracker ?? PinnedBlockTrackerService.instance,
       library = library ?? TheoryBlockLibraryService.instance,
       evaluator = evaluator ?? const DecayRecallEvaluatorService();

  final PinnedBlockTrackerService tracker;
  final TheoryBlockLibraryService library;
  final DecayRecallEvaluatorService evaluator;

  /// Returns booster suggestions for pinned blocks with decayed tags.
  Future<List<PinnedBlockBoosterSuggestion>> getBoosters() async {
    final ids = await tracker.getPinnedBlockIds();
    if (ids.isEmpty) return [];
    await library.loadAll();
    final suggestions = <PinnedBlockBoosterSuggestion>[];
    for (final id in ids) {
      final block = library.getById(id);
      if (block == null) continue;
      final decayed = await evaluator.getDecayedTags(block);
      if (decayed.isEmpty) continue;
      for (final tag in decayed) {
        final hasPack = block.practicePackIds.isNotEmpty;
        suggestions.add(
          PinnedBlockBoosterSuggestion(
            blockId: block.id,
            blockTitle: block.title,
            tag: tag,
            action: hasPack ? 'resumePack' : 'reviewTheory',
            packId: hasPack ? block.practicePackIds.first : null,
          ),
        );
      }
    }
    return suggestions;
  }
}
