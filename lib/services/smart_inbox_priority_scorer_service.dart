import 'package:shared_preferences/shared_preferences.dart';

import '../utils/shared_prefs_keys.dart';
import 'smart_pinned_block_booster_provider.dart';

/// Scores and sorts booster suggestions by urgency for the smart inbox.
class SmartInboxPriorityScorerService {
  /// Returns [input] sorted by urgency and recency.
  Future<List<PinnedBlockBoosterSuggestion>> sort(
      List<PinnedBlockBoosterSuggestion> input) async {
    if (input.isEmpty) return [];

    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final scored = <_ScoredSuggestion>[];
    for (final s in input) {
      final base = _scoreForAction(s.action);
      final lastMillis =
          prefs.getInt(SharedPrefsKeys.boosterInboxLast(s.tag));
      final last = lastMillis == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastMillis);
      final ageMs =
          last == null ? double.infinity : now.difference(last).inMilliseconds.toDouble();
      scored.add(_ScoredSuggestion(s, base, ageMs));
    }

    scored.sort((a, b) {
      final cmp = b.base.compareTo(a.base);
      if (cmp != 0) return cmp;
      return b.ageMs.compareTo(a.ageMs); // older first
    });

    return scored.map((s) => s.suggestion).toList();
  }

  int _scoreForAction(String action) {
    switch (action) {
      case 'decayBooster':
        return 3;
      case 'reviewTheory':
        return 2;
      case 'resumePack':
      default:
        return 1;
    }
  }
}

class _ScoredSuggestion {
  final PinnedBlockBoosterSuggestion suggestion;
  final int base;
  final double ageMs;
  _ScoredSuggestion(this.suggestion, this.base, this.ageMs);
}
