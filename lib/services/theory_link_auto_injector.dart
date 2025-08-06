import '../models/inline_theory_entry.dart';
import '../models/v2/training_pack_spot.dart';

/// Injects references to [InlineTheoryEntry] into [TrainingPackSpot] metadata
/// based on matching tags.
class TheoryLinkAutoInjector {
  const TheoryLinkAutoInjector();

  /// Inserts theory references into [spots] using [theoryIndex].
  ///
  /// [theoryIndex] should map theory tags to their corresponding
  /// [InlineTheoryEntry]. For each spot, the first matching entry is inserted
  /// into `spot.meta['theory']`. Duplicate theory ids across the provided
  /// [spots] are avoided.
  void injectAll(
    List<TrainingPackSpot> spots,
    Map<String, InlineTheoryEntry> theoryIndex,
  ) {
    final used = <String>{};
    for (final spot in spots) {
      for (final t in spot.tags) {
        final entry = _findEntry(t, theoryIndex);
        if (entry == null) continue;
        final id = entry.id ?? entry.tag;
        if (used.contains(id)) continue;
        spot.meta['theory'] = {
          'tag': entry.tag,
          'id': id,
          if (entry.title != null) 'title': entry.title,
        };
        used.add(id);
        break;
      }
    }
  }

  InlineTheoryEntry? _findEntry(
    String tag,
    Map<String, InlineTheoryEntry> index,
  ) {
    // Exact match first
    if (index.containsKey(tag)) return index[tag];

    final tagLower = tag.toLowerCase();
    for (final e in index.entries) {
      final keyLower = e.key.toLowerCase();
      if (tagLower == keyLower) return e.value;
    }

    // Fuzzy match: check if one tag contains the other.
    for (final e in index.entries) {
      final keyLower = e.key.toLowerCase();
      if (tagLower.contains(keyLower) || keyLower.contains(tagLower)) {
        return e.value;
      }
    }
    return null;
  }
}

