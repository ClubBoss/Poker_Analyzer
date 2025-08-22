import 'package:uuid/uuid.dart';

import '../models/v2/training_pack_template_v2.dart';
import 'theory_injection_engine.dart';

/// Generates booster packs by injecting theory spots into a base pack.
class TheoryBoosterGenerator {
  final TheoryInjectionEngine _engine;
  final Uuid _uuid;

  TheoryBoosterGenerator({
    TheoryInjectionEngine engine = const TheoryInjectionEngine(),
    Uuid uuid = const Uuid(),
  }) : _engine = engine,
       _uuid = uuid;

  /// Returns a new training pack with theory inserted from the most relevant
  /// theory pack in [allTheoryPacks]. Relevance is determined by tag overlap
  /// with [basePack]. The result has a new id and `meta['booster'] = true`.
  TrainingPackTemplateV2 generateBooster({
    required TrainingPackTemplateV2 basePack,
    required List<TrainingPackTemplateV2> allTheoryPacks,
  }) {
    final theory = _selectTheory(basePack, allTheoryPacks);
    final mixed = _engine.injectTheory(basePack, theory, interval: 3);
    final map = mixed.toJson();
    map['id'] = _uuid.v4();
    final meta = Map<String, dynamic>.from(map['meta'] ?? {});
    meta['booster'] = true;
    map['meta'] = meta;
    final result = TrainingPackTemplateV2.fromJson(
      Map<String, dynamic>.from(map),
    );
    result.trainingType = basePack.trainingType;
    return result;
  }

  TrainingPackTemplateV2 _selectTheory(
    TrainingPackTemplateV2 base,
    List<TrainingPackTemplateV2> theoryPacks,
  ) {
    if (theoryPacks.isEmpty) return base;
    final baseTags = base.tags.map((e) => e.toLowerCase()).toSet();
    TrainingPackTemplateV2? best;
    var bestScore = -1;
    for (final t in theoryPacks) {
      final tags = t.tags.map((e) => e.toLowerCase()).toSet();
      final score = tags.intersection(baseTags).length;
      if (score > bestScore) {
        best = t;
        bestScore = score;
      }
    }
    return best ?? theoryPacks.first;
  }
}
