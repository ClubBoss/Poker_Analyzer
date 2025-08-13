import 'package:uuid/uuid.dart';
import '../../../models/v2/training_pack_spot.dart';
import '../../../models/v2/training_pack_template_v2.dart';
import '../../../models/v2/hand_data.dart';
import '../../../models/v2/hero_position.dart';
import 'board_similarity_engine.dart';

class TrainingSpotExpander {
  final Uuid _uuid;
  final BoardSimilarityEngine _boardEngine;

  const TrainingSpotExpander({Uuid? uuid, BoardSimilarityEngine? boardEngine})
      : _uuid = uuid ?? const Uuid(),
        _boardEngine = boardEngine ?? const BoardSimilarityEngine();

  List<TrainingPackSpot> expand(TrainingPackSpot spot) {
    final results = <TrainingPackSpot>[spot];
    if (spot.hand.board.length >= 3) {
      results.add(_boardVariant(spot));
    }
    results.add(_stackVariant(spot, diff: 2));
    results.add(_stackVariant(spot, diff: -2));
    if (spot.hand.position != HeroPosition.unknown) {
      results.add(_positionVariant(spot));
    }
    return results;
  }

  TrainingPackTemplateV2 expandPack(TrainingPackTemplateV2 pack) {
    final expanded = <TrainingPackSpot>[];
    for (final s in pack.spots) {
      expanded.addAll(expand(s));
    }
    final map = pack.toJson();
    map['spots'] = [for (final s in expanded) s.toJson()];
    map['spotCount'] = expanded.length;
    return TrainingPackTemplateV2.fromJson(Map<String, dynamic>.from(map));
  }

  TrainingPackSpot _clone(TrainingPackSpot spot) {
    final hand =
        HandData.fromJson(Map<String, dynamic>.from(spot.hand.toJson()));
    final copy = spot.copyWith(
      id: _uuid.v4(),
      hand: hand,
      meta: {
        ...spot.meta,
        'variation': true,
      },
    );
    return copy;
  }

  TrainingPackSpot _boardVariant(TrainingPackSpot spot) {
    final clone = _clone(spot);
    final board = List<String>.from(clone.hand.board);
    if (board.length >= 3) {
      final newFlop = _boardEngine.getSimilarFlop(board.take(3).toList());
      if (newFlop.isNotEmpty) {
        for (int i = 0; i < 3; i++) {
          board[i] = newFlop[i];
        }
        clone.hand.board = board;
      }
    }
    return clone;
  }

  TrainingPackSpot _stackVariant(TrainingPackSpot spot, {int diff = 2}) {
    final clone = _clone(spot);
    clone.hand.stacks = {
      for (final e in spot.hand.stacks.entries) e.key: e.value + diff
    };
    return clone;
  }

  TrainingPackSpot _positionVariant(TrainingPackSpot spot) {
    final clone = _clone(spot);
    const values = HeroPosition.values;
    final idx = values.indexOf(spot.hand.position);
    if (idx >= 0 && idx + 1 < values.length) {
      clone.hand.position = values[idx + 1];
    }
    return clone;
  }
}
