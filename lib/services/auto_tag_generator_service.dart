import 'dart:math';

import '../models/v2/training_pack_template.dart';

class AutoTagGeneratorService {
  AutoTagGeneratorService();

  List<String> generateTags(TrainingPackTemplate tpl) {
    final tags = <String>{};
    if (tpl.heroBbStack > 0) tags.add('${tpl.heroBbStack}bb');
    tags.add(tpl.heroPos.label);
    if (tpl.spots.isNotEmpty) {
      final street = tpl.spots.map((e) => e.street).reduce(max);
      const names = ['preflop', 'flop', 'turn', 'river'];
      tags.add(names[street]);
    }
    final heroActs = <String>[];
    final oppActs = <String>[];
    for (final s in tpl.spots) {
      for (final list in s.hand.actions.values) {
        for (final a in list) {
          if (a.playerIndex == s.hand.heroIndex) {
            heroActs.add(a.action.toLowerCase());
          } else {
            oppActs.add(a.action.toLowerCase());
          }
        }
      }
    }
    if (heroActs.isNotEmpty) {
      final counts = <String, int>{};
      for (final a in heroActs) {
        counts[a] = (counts[a] ?? 0) + 1;
      }
      tags.add(counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key);
    }
    if (oppActs.isNotEmpty) {
      const aggr = {'bet', 'raise', '3bet', 'push'};
      var aggrCount = 0;
      for (final a in oppActs) {
        if (aggr.contains(a)) aggrCount++;
      }
      final ratio = aggrCount / oppActs.length;
      tags.add(ratio >= 0.6 ? 'aggressive' : 'passive');
    }
    return tags.toList();
  }
}
