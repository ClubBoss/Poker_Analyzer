import '../models/inline_theory_entry.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/training_pack_model.dart';

/// Injects references to [InlineTheoryEntry] into [TrainingPackSpot]s based on
/// matching tags.
class TheoryLinkAutoInjector {
  const TheoryLinkAutoInjector();

  /// Attaches theory links to all spots within [model] using [theoryIndex].
  ///
  /// Returns the mutated [model] for convenience and logs the number of
  /// injected links.
  TrainingPackModel injectLinks(
    TrainingPackModel model,
    Map<String, InlineTheoryEntry> theoryIndex,
  ) {
    final count = _injectAll(model.spots, theoryIndex);
    if (count > 0) {
      print('TheoryLinkAutoInjector: injected $count links');
    }
    return model;
  }

  /// Convenience method to inject links into a list of [spots].
  void injectAll(
    List<TrainingPackSpot> spots,
    Map<String, InlineTheoryEntry> theoryIndex,
  ) {
    final count = _injectAll(spots, theoryIndex);
    if (count > 0) {
      print('TheoryLinkAutoInjector: injected $count links');
    }
  }

  int _injectAll(
    List<TrainingPackSpot> spots,
    Map<String, InlineTheoryEntry> theoryIndex,
  ) {
    final used = <String>{};
    var injected = 0;
    for (final spot in spots) {
      if (spot.inlineTheory != null) {
        final id = spot.inlineTheory!.id ?? spot.inlineTheory!.tag;
        used.add(id);
        continue;
      }
      for (final t in spot.tags) {
        final entry = _findEntry(t, theoryIndex);
        if (entry == null) continue;
        final id = entry.id ?? entry.tag;
        if (used.contains(id)) continue;
        spot.inlineTheory = entry;
        spot.meta['theory'] = {
          'tag': entry.tag,
          'id': id,
          if (entry.title != null) 'title': entry.title,
        };
        used.add(id);
        injected++;
        break;
      }
    }
    return injected;
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

