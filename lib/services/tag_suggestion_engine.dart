import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/hero_position.dart';

class TagSuggestionEngine {
  TagSuggestionEngine();

  List<String> suggestTags(TrainingPackTemplateV2 pack) {
    final set = <String>{};
    final posSet = <HeroPosition>{};
    for (final s in pack.spots) {
      posSet.add(s.hand.position);
    }
    if (posSet.isNotEmpty &&
        posSet.every(
          (p) =>
              p == HeroPosition.btn ||
              p == HeroPosition.sb ||
              p == HeroPosition.bb,
        )) {
      set.add('blind_defense');
    }
    if (pack.spots.isNotEmpty &&
        pack.spots.every((s) => s.hand.playerCount == 6)) {
      set.add('6max');
    }
    if (pack.bb == 10) set.add('10bb');
    final aud = pack.audience?.toLowerCase();
    if (aud == 'beginner') set.add('beginner');
    final kw = pack.meta['keywords'];
    if (kw is List) {
      for (final k in kw) {
        if (k is String && k.isNotEmpty) set.add(k);
      }
    } else if (kw is String) {
      for (final w in kw.split(RegExp(r'[;, ]+'))) {
        if (w.isNotEmpty) set.add(w);
      }
    }
    final list = set.toList()..sort();
    return list;
  }
}
