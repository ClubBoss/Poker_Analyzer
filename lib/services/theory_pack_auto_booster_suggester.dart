import '../models/theory_pack_model.dart';
import 'theory_pack_auto_tagger.dart';
import 'theory_pack_review_status_engine.dart';

/// Suggests booster theory packs related to a given pack.
class TheoryPackAutoBoosterSuggester {
  TheoryPackAutoBoosterSuggester();

  /// Returns up to [max] booster pack ids ranked by relevance.
  List<String> suggestBoosters(
    TheoryPackModel pack,
    List<TheoryPackModel> all, {
    int max = 5,
  }) {
    const tagger = TheoryPackAutoTagger();
    const reviewEngine = TheoryPackReviewStatusEngine();
    final baseTags = tagger
        .autoTag(pack)
        .map((e) => e.toLowerCase().trim())
        .toSet();
    final baseWords = _keywords(pack);

    final scored = <(String, double)>[];
    for (final other in all) {
      if (other.id == pack.id) continue;
      if (reviewEngine.getStatus(other) != ReviewStatus.approved) continue;
      final tags = tagger
          .autoTag(other)
          .map((e) => e.toLowerCase().trim())
          .toSet();
      final words = _keywords(other);

      final tagInter = tags.intersection(baseTags).length.toDouble();
      final tagUnion = tags.union(baseTags).length.toDouble();
      final tagScore = tagUnion == 0 ? 0 : tagInter / tagUnion;

      final wordInter = words.intersection(baseWords).length.toDouble();
      final wordUnion = words.union(baseWords).length.toDouble();
      final wordScore = wordUnion == 0 ? 0 : wordInter / wordUnion;

      final score = tagScore * 0.6 + wordScore * 0.4;
      if (score > 0) scored.add((other.id, score));
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final s in scored.take(max)) s.$1];
  }

  Set<String> _keywords(TheoryPackModel pack) {
    final buffer = StringBuffer(pack.title.toLowerCase());
    for (final s in pack.sections) {
      buffer
        ..write(' ')
        ..write(s.title.toLowerCase())
        ..write(' ')
        ..write(s.text.toLowerCase());
    }
    final words = buffer.toString().split(RegExp(r'\W+'));
    return {
      for (final w in words)
        if (w.isNotEmpty && w.length > 3) w,
    };
  }
}
