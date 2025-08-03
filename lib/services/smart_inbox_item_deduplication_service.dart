import 'booster_interaction_tracker_service.dart';
import 'smart_pinned_block_booster_provider.dart';
import 'smart_booster_exclusion_tracker_service.dart';

/// Removes redundant smart inbox boosters targeting the same tag or block.
class SmartInboxItemDeduplicationService {
  SmartInboxItemDeduplicationService({
    BoosterInteractionTrackerService? interactions,
  }) : interactions = interactions ?? BoosterInteractionTrackerService.instance;

  final BoosterInteractionTrackerService interactions;

  /// Filters [input] keeping the highest priority suggestion per tag and block.
  /// Priority is determined by how long ago the booster was shown and preferring
  /// `resumePack` over `reviewTheory` when ties occur.
  Future<List<PinnedBlockBoosterSuggestion>> deduplicate(
      List<PinnedBlockBoosterSuggestion> input) async {
    if (input.isEmpty) return [];

    final now = DateTime.now();
    final summary = await interactions.getSummary();

    final scored = <_ScoredSuggestion>[];
    for (final s in input) {
      final info = summary[s.tag];
      DateTime? last;
      if (info != null) {
        final opened = info['opened'];
        final dismissed = info['dismissed'];
        if (opened != null && dismissed != null) {
          last = opened.isAfter(dismissed) ? opened : dismissed;
        } else {
          last = opened ?? dismissed;
        }
      }
      final ageMs =
          last == null ? double.infinity : now.difference(last).inMilliseconds.toDouble();
      final isResumePack = s.action == 'resumePack';
      scored.add(_ScoredSuggestion(s, ageMs, isResumePack));
    }

    scored.sort((a, b) {
      final cmp = b.ageMs.compareTo(a.ageMs);
      if (cmp != 0) return cmp;
      if (a.isResumePack == b.isResumePack) return 0;
      return b.isResumePack ? 1 : -1; // resumePack preferred
    });

    final byTag = <String, PinnedBlockBoosterSuggestion>{};
    final byBlock = <String, PinnedBlockBoosterSuggestion>{};
    final result = <PinnedBlockBoosterSuggestion>[];
    for (final s in scored) {
      final tag = s.suggestion.tag;
      final block = s.suggestion.blockId;
      if (byTag.containsKey(tag) || byBlock.containsKey(block)) {
        await SmartBoosterExclusionTrackerService()
            .logExclusion(tag, 'deduplicated');
        continue;
      }
      byTag[tag] = s.suggestion;
      byBlock[block] = s.suggestion;
      result.add(s.suggestion);
    }
    return result;
  }
}

class _ScoredSuggestion {
  final PinnedBlockBoosterSuggestion suggestion;
  final double ageMs;
  final bool isResumePack;
  _ScoredSuggestion(this.suggestion, this.ageMs, this.isResumePack);
}
