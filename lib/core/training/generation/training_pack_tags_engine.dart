import '../../../models/v2/training_pack_template_v2.dart';
import '../../../models/v2/hero_position.dart';

class TrainingPackTagsEngine {
  const TrainingPackTagsEngine();

  List<String> generate(TrainingPackTemplateV2 template) {
    final set = <String>{};
    final positions = <HeroPosition>{};
    var streets = <int>{};
    var pushfold = false;
    var river = false;
    for (final s in template.spots) {
      positions.add(s.hand.position);
      streets.add(s.street);
      final st = s.hand.stacks['${s.hand.heroIndex}']?.round();
      if (st != null && st == 10) pushfold = true;
      if (s.hand.board.length >= 5) river = true;
    }
    if (streets.length >= 2) set.add('postflop');
    if (pushfold || template.bb == 10) set.add('pushfold');
    if (positions.length >= 3 || template.positions.length >= 3) set.add('multiway');
    if (river) set.add('river');
    final list = set.toList();
    list.sort();
    return list;
  }
}
