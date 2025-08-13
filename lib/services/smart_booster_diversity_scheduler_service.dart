import 'dart:math';

import 'booster_interaction_tracker_service.dart';
import 'smart_pinned_block_booster_provider.dart';
import 'smart_booster_exclusion_tracker_service.dart';
import 'smart_booster_inbox_limiter_service.dart';

/// Schedules booster suggestions to maximize variety and penalize recent repeats.
class SmartBoosterDiversitySchedulerService {
  SmartBoosterDiversitySchedulerService({
    BoosterInteractionTrackerService? interactions,
  }) : interactions = interactions ?? BoosterInteractionTrackerService.instance;

  final BoosterInteractionTrackerService interactions;

  /// Returns [all] suggestions ordered to avoid repetitive nudges.
  Future<List<PinnedBlockBoosterSuggestion>> schedule(
      List<PinnedBlockBoosterSuggestion> all) async {
    if (all.isEmpty) return [];

    final now = DateTime.now();
    final uniqueTags = all.map((s) => s.tag).toSet();
    final tagTimes = <String, DateTime?>{};
    for (final tag in uniqueTags) {
      final opened = await interactions.getLastOpened(tag);
      final dismissed = await interactions.getLastDismissed(tag);
      DateTime? last;
      if (opened != null && dismissed != null) {
        last = opened.isAfter(dismissed) ? opened : dismissed;
      } else {
        last = opened ?? dismissed;
      }
      tagTimes[tag] = last;
    }

    final byTag = <String, List<_ScoredSuggestion>>{};
    for (final s in all) {
      final last = tagTimes[s.tag];
      double score;
      if (last == null) {
        score = 1000; // never shown
      } else {
        final age = now.difference(last).inDays.toDouble();
        score = age >= 7 ? age : age - 7; // penalize recent (<7 days)
      }
      byTag.putIfAbsent(s.tag, () => []).add(_ScoredSuggestion(s, score));
    }

    for (final list in byTag.values) {
      list.sort((a, b) => b.score.compareTo(a.score));
    }

    final tags = byTag.keys.toList()
      ..sort((a, b) => byTag[b]![0].score.compareTo(byTag[a]![0].score));

    final rnd = Random();
    final result = <PinnedBlockBoosterSuggestion>[];
    var added = true;
    while (added && result.length < SmartBoosterInboxLimiterService.maxPerDay) {
      added = false;
      for (final tag in tags) {
        if (result.length >= SmartBoosterInboxLimiterService.maxPerDay) {
          break;
        }
        final list = byTag[tag]!;
        if (list.isNotEmpty) {
          // add slight randomness to avoid deterministic ordering within same score
          final next = list.removeAt(0);
          result.add(next.suggestion);
          added = true;
        }
      }
      // shuffle tags each round to enhance diversity
      tags.shuffle(rnd);
    }

    for (final list in byTag.values) {
      for (final leftover in list) {
        await SmartBoosterExclusionTrackerService()
            .logExclusion(leftover.suggestion.tag, 'filteredByType');
      }
    }

    return result;
  }
}

class _ScoredSuggestion {
  final PinnedBlockBoosterSuggestion suggestion;
  final double score;
  _ScoredSuggestion(this.suggestion, this.score);
}
