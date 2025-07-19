import 'package:uuid/uuid.dart';
import '../../../models/v2/training_pack_spot.dart';
import '../../../models/v2/training_pack_template_v2.dart';
import '../../../models/v2/hand_data.dart';
import '../../../models/v2/hero_position.dart';

class TrainingSpotExpander {
  final Uuid _uuid;
  const TrainingSpotExpander({Uuid? uuid}) : _uuid = uuid ?? const Uuid();

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
    final hand = HandData.fromJson(Map<String, dynamic>.from(spot.hand.toJson()));
    final copy = spot.copyWith(
      id: _uuid.v4(),
      hand: hand,
    );
    copy.isGenerated = true;
    return copy;
  }

  TrainingPackSpot _boardVariant(TrainingPackSpot spot) {
    final clone = _clone(spot);
    final board = List<String>.from(clone.hand.board);
    if (board.length >= 3) {
      const ranks = ['2','3','4','5','6','7','8','9','T','J','Q','K','A'];
      final next = {
        for (int i = 0; i < ranks.length; i++)
          ranks[i]: ranks[(i + 1) % ranks.length]
      };
      for (int i = 0; i < 3 && i < board.length; i++) {
        final c = board[i];
        final r = c[0].toUpperCase();
        final s = c.substring(1);
        final nr = next[r] ?? r;
        board[i] = '$nr$s';
      }
      clone.hand.board = board;
    }
    return clone;
  }

  TrainingPackSpot _stackVariant(TrainingPackSpot spot, {int diff = 2}) {
    final clone = _clone(spot);
    clone.hand.stacks = {
      for (final e in spot.hand.stacks.entries)
        e.key: e.value + diff
    };
    return clone;
  }

  TrainingPackSpot _positionVariant(TrainingPackSpot spot) {
    final clone = _clone(spot);
    final values = HeroPosition.values;
    final idx = values.indexOf(spot.hand.position);
    if (idx >= 0 && idx + 1 < values.length) {
      clone.hand.position = values[idx + 1];
    }
    return clone;
  }
}
