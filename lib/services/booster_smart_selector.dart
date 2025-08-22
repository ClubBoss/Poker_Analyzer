import '../helpers/hand_utils.dart';
import '../models/v2/hero_position.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import 'booster_cluster_engine.dart';

/// Selects a diverse subset of spots for booster packs.
class BoosterSmartSelector {
  BoosterSmartSelector();

  /// Returns a copy of [pack] containing at most [maxSpots] of the most
  /// representative spots from [pack] and [clusters].
  TrainingPackTemplateV2 selectBest(
    TrainingPackTemplateV2 pack,
    List<SpotCluster> clusters, {
    int maxSpots = 30,
  }) {
    if (pack.spots.isEmpty) {
      return TrainingPackTemplateV2.fromJson(pack.toJson());
    }

    final candidates = <TrainingPackSpot>[];
    final idSet = <String>{};
    for (final s in pack.spots) {
      if (idSet.add(s.id)) candidates.add(s);
    }
    for (final c in clusters) {
      for (final s in c.spots) {
        if (idSet.add(s.id)) candidates.add(s);
      }
    }

    final positions = <HeroPosition>{};
    final hands = <String>{};
    final boards = <String>{};
    final actions = <String>{};

    final selected = <TrainingPackSpot>[];
    final remaining = List<TrainingPackSpot>.from(candidates);

    String boardKey(TrainingPackSpot s) {
      final b = s.board.isNotEmpty ? s.board : s.hand.board;
      return b.join('/');
    }

    String actionKey(TrainingPackSpot s) {
      return s.correctAction ?? s.type;
    }

    int score(TrainingPackSpot s) {
      var sc = 0;
      if (!positions.contains(s.hand.position)) sc++;
      final code = handCode(s.hand.heroCards) ?? s.hand.heroCards;
      if (!hands.contains(code)) sc++;
      if (!boards.contains(boardKey(s))) sc++;
      if (!actions.contains(actionKey(s))) sc++;
      return sc;
    }

    while (remaining.isNotEmpty && selected.length < maxSpots) {
      remaining.sort((a, b) => score(b).compareTo(score(a)));
      final best = remaining.removeAt(0);
      positions.add(best.hand.position);
      final code = handCode(best.hand.heroCards) ?? best.hand.heroCards;
      hands.add(code);
      boards.add(boardKey(best));
      actions.add(actionKey(best));
      selected.add(best);
    }

    final map = pack.toJson();
    map['spots'] = [for (final s in selected) s.toJson()];
    map['spotCount'] = selected.length;
    final result = TrainingPackTemplateV2.fromJson(
      Map<String, dynamic>.from(map),
    );
    result.isGeneratedPack = pack.isGeneratedPack;
    result.isSampledPack = pack.isSampledPack;
    return result;
  }
}
