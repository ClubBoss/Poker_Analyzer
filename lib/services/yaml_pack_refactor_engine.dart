import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hero_position.dart';

class YamlPackRefactorEngine {
  const YamlPackRefactorEngine();

  TrainingPackTemplateV2 refactor(TrainingPackTemplateV2 pack) {
    pack.goal = _cleanText(pack.goal);
    pack.description = _cleanText(pack.description);
    pack.meta.removeWhere(
      (k, _) =>
          k == 'generatedAt' ||
          k == 'legacyScore' ||
          (k.toString().startsWith('legacy')),
    );
    pack.meta['schemaVersion'] = '2.0.0';
    pack.spots.sort(_spotCompare);
    return pack;
  }

  int _spotCompare(TrainingPackSpot a, TrainingPackSpot b) {
    final p = a.priority.compareTo(b.priority);
    if (p != 0) return p;
    final h = a.hand.heroCards.compareTo(b.hand.heroCards);
    if (h != 0) return h;
    final ai = kPositionOrder.indexOf(a.hand.position);
    final bi = kPositionOrder.indexOf(b.hand.position);
    return ai.compareTo(bi);
  }

  String _cleanText(String s) {
    var v = s.replaceAll('\r', '');
    v = v.replaceAll(RegExp(r'\n\s*\n+'), '\n');
    return v.trim();
  }
}
