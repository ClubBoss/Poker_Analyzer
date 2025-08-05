import '../models/constraint_set.dart';
import '../models/spot_seed_format.dart';
import '../models/card_model.dart';
import '../models/v2/training_pack_spot.dart';
import 'constraint_resolver_engine_v2.dart';

class SpotSeedFilterService {
  final ConstraintResolverEngine _engine;

  const SpotSeedFilterService({ConstraintResolverEngine? engine})
    : _engine = engine ?? const ConstraintResolverEngine();

  /// Filters [spots] returning only those that satisfy [constraints].
  ///
  /// Each [TrainingPackSpot] is converted to a [SpotSeedFormat] and validated
  /// using [ConstraintResolverEngine.isValid].
  List<TrainingPackSpot> filter(
    List<TrainingPackSpot> spots,
    ConstraintSet constraints,
  ) {
    return [
      for (final spot in spots)
        if (_matches(spot, constraints)) spot,
    ];
  }

  bool _matches(TrainingPackSpot spot, ConstraintSet constraints) {
    if (constraints.tags.isNotEmpty) {
      final tags = spot.tags.map((t) => t.toLowerCase()).toSet();
      final required = constraints.tags.map((t) => t.toLowerCase()).toList();
      if (!required.every(tags.contains)) {
        return false;
      }
    }
    final seed = _toSeed(spot);
    return _engine.isValid(seed, constraints);
  }

  SpotSeedFormat _toSeed(TrainingPackSpot spot) {
    final board = [
      for (final c in spot.board)
        CardModel(rank: c[0], suit: c.length > 1 ? c[1] : ''),
    ];
    final heroPos = spot.hand.position.name;
    final actions = <String>[];
    if (spot.villainAction != null && spot.villainAction!.isNotEmpty) {
      actions.add(spot.villainAction!.split(' ').first);
    }
    final stack = spot.hand.stacks['0'];
    return SpotSeedFormat(
      player: 'hero',
      handGroup: const [],
      position: heroPos,
      heroStack: stack,
      board: board,
      villainActions: actions,
      tags: spot.tags,
    );
  }
}
