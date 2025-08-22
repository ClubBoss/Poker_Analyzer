import 'package:uuid/uuid.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/hero_position.dart';
import '../helpers/poker_position_helper.dart';

class PackLibraryAutoFixEngine {
  PackLibraryAutoFixEngine();

  TrainingPackTemplateV2 autoFix(TrainingPackTemplateV2 pack) {
    final id = pack.id.trim().isEmpty ? const Uuid().v4() : pack.id;
    final tags = <String>{};
    for (final t in pack.tags) {
      final v = t.trim();
      if (v.isEmpty) continue;
      tags.add(v);
    }
    final meta = Map<String, dynamic>.from(pack.meta);
    meta['schemaVersion'] = '2.0.0';
    final bb = pack.bb <= 0 ? 10 : pack.bb;
    for (final s in pack.spots) {
      final hand = s.hand;
      if (hand.position == HeroPosition.unknown) {
        final order = getPositionList(hand.playerCount);
        if (hand.heroIndex >= 0 && hand.heroIndex < order.length) {
          hand.position = parseHeroPosition(order[hand.heroIndex]);
        }
      }
      hand.stacks.updateAll((k, v) => v <= 0 ? 10 : v);
    }
    return TrainingPackTemplateV2(
      id: id,
      name: _limit(pack.name),
      description: _limit(pack.description),
      goal: _limit(pack.goal),
      audience: pack.audience,
      tags: tags.toList(),
      category: pack.category,
      trainingType: pack.trainingType,
      spots: pack.spots,
      spotCount: pack.spots.length,
      created: pack.created,
      gameType: pack.gameType,
      bb: bb,
      positions: pack.positions,
      meta: meta,
      recommended: pack.recommended,
    );
  }

  String _limit(String s) => s.length > 100 ? s.substring(0, 100) : s;
}
