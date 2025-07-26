import '../models/theory_pack_model.dart';

/// Generates automatic tags for a [TheoryPackModel].
class TheoryPackAutoTagger {
  const TheoryPackAutoTagger();

  /// Returns a set of tags detected in [pack] using simple
  /// keyword heuristics over all section titles and texts.
  Set<String> autoTag(TheoryPackModel pack) {
    final buffer = StringBuffer(pack.title.toLowerCase());
    for (final s in pack.sections) {
      buffer
        ..write(' ')
        ..write(s.title.toLowerCase())
        ..write(' ')
        ..write(s.text.toLowerCase());
    }
    final text = buffer.toString();
    final tags = <String>{};

    bool containsAny(List<String> words) {
      for (final w in words) {
        if (text.contains(w)) return true;
      }
      return false;
    }

    if (text.contains('bubble')) tags.add('bubble');
    if (containsAny(['shortstack', 'short stack'])) tags.add('shortstack');
    if (text.contains('icm')) tags.add('ICM');
    if (containsAny(['deepstack', 'deep stack'])) tags.add('deepstack');
    if (containsAny(['final table', 'final-table', 'finaltable'])) {
      tags.add('final table');
    }
    if (text.contains('preflop')) tags.add('preflop');
    if (containsAny(['postflop', 'flop', 'turn', 'river']))
      tags.add('postflop');
    if (text.contains('exploit')) tags.add('exploit');
    if (text.contains('live')) tags.add('live');

    return tags;
  }
}
