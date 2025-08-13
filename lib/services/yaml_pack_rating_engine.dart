import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import 'yaml_pack_balance_analyzer.dart';

class YamlPackRatingEngine {
  const YamlPackRatingEngine();

  int rate(TrainingPackTemplateV2 pack) {
    final spots = pack.spots;
    final actions = spots.where(_hasHeroAction).length;
    final evaluated = spots.where((s) => s.evalResult != null).length;
    final positions = <String>{
      ...pack.positions,
      for (final s in spots) s.hand.position.name
    }..removeWhere((e) => e.trim().isEmpty);
    final streets = {for (final s in spots) s.street};
    final stacks = {
      for (final s in spots) s.hand.stacks['${s.hand.heroIndex}']?.round() ?? 0
    };
    final ev = (pack.meta['evScore'] as num?)?.toDouble() ?? 0;
    final diff = (pack.meta['rankScore'] as num?)?.toDouble() ?? 0;
    var score = 0.0;
    if (pack.description.trim().isNotEmpty) score += 5;
    if (pack.goal.trim().isNotEmpty) score += 5;
    if (pack.meta.isNotEmpty) score += 5;
    score += ev * 0.2;
    score += diff * 20;
    score += positions.length.clamp(0, 4) * 2.5;
    score += streets.length.clamp(0, 4) * 2.5;
    score += stacks.length.clamp(0, 5) * 2;
    if (spots.isNotEmpty) {
      score += actions * 5 / spots.length;
      score += evaluated * 5 / spots.length;
    }
    var penalty = 10.0;
    for (final i in const YamlPackBalanceAnalyzer().analyze(pack)) {
      penalty += i.severity * 2;
    }
    score -= penalty;
    if (score < 0) score = 0;
    if (score > 100) score = 100;
    return score.round();
  }

  Map<String, int> rateAll(List<TrainingPackTemplateV2> packs) {
    final res = <String, int>{};
    for (final p in packs) {
      res[p.id] = rate(p);
    }
    return res;
  }

  bool _hasHeroAction(TrainingPackSpot s) {
    final hero = s.hand.heroIndex;
    for (final list in s.hand.actions.values) {
      for (final a in list) {
        if (a.playerIndex == hero) return true;
      }
    }
    return false;
  }
}
