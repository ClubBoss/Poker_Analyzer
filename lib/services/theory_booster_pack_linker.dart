import '../models/theory_pack_model.dart';
import 'theory_pack_auto_tagger.dart';
import 'theory_pack_auto_booster_suggester.dart';
import 'theory_pack_review_status_engine.dart';

/// Links booster theory packs to a given theory module.
class TheoryBoosterPackLinker {
  const TheoryBoosterPackLinker();

  /// Returns up to 3 booster pack ids relevant to [theoryPack].
  List<String> autoLinkBoosters(
    TheoryPackModel theoryPack,
    List<TheoryPackModel> allBoosters,
  ) {
    const tagger = TheoryPackAutoTagger();
    const suggester = TheoryPackAutoBoosterSuggester();
    const reviewEngine = TheoryPackReviewStatusEngine();

    final baseTags =
        tagger.autoTag(theoryPack).map((e) => e.toLowerCase().trim()).toSet();

    final candidates = <TheoryPackModel>[];
    for (final b in allBoosters) {
      if (b.id == theoryPack.id) continue;
      if (!_isBooster(b)) continue;
      if (reviewEngine.getStatus(b) != ReviewStatus.approved) continue;
      candidates.add(b);
    }

    final suggested = suggester.suggestBoosters(theoryPack, candidates, max: 5);

    final scored = <(String, double)>[];
    for (final id in suggested) {
      final pack = candidates.firstWhere((e) => e.id == id);
      final tags =
          tagger.autoTag(pack).map((e) => e.toLowerCase().trim()).toSet();
      final inter = tags.intersection(baseTags).length.toDouble();
      final union = tags.union(baseTags).length.toDouble();
      var score = union == 0 ? 0 : inter / union;
      final wc = _wordCount(pack);
      if (wc < 300) score += 0.05;
      scored.add((pack.id, score));
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    return [for (final s in scored.take(3)) s.$1];
  }

  bool _isBooster(TheoryPackModel pack) {
    final id = pack.id.toLowerCase();
    final title = pack.title.toLowerCase();
    if (id.contains('booster') || title.contains('booster')) return true;
    for (final s in pack.sections) {
      if (s.type.toLowerCase().contains('booster')) return true;
    }
    return false;
  }

  int _wordCount(TheoryPackModel pack) {
    return pack.sections.fold<int>(
      0,
      (sum, s) =>
          sum + s.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length,
    );
  }
}
