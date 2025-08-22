import '../models/v2/training_pack_spot.dart';
import '../models/spot_line_graph.dart';
import '../models/action_entry.dart';

class SpotLineGraphEngine {
  SpotLineGraphEngine();

  SpotLineGraph build(TrainingPackSpot spot) {
    final heroIndex = spot.hand.heroIndex;
    final heroPos = spot.hand.position.name;
    final heroStack =
        spot.hand.stacks[heroIndex.toString()] ?? spot.hand.stacks['0'] ?? 0;

    final root = SpotLineNode(
      street: 0,
      stack: heroStack,
      pot: 0,
      heroPosition: heroPos,
    );

    SpotLineNode current = root;
    for (var street = 0; street < spot.hand.actions.length; street++) {
      final acts = spot.hand.actions[street] ?? [];
      for (final ActionEntry act in acts) {
        final actor = act.playerIndex == heroIndex ? 'hero' : 'villain';
        final next = SpotLineNode(
          street: act.street,
          stack: current.stack,
          pot: act.potAfter,
          heroPosition: heroPos,
          actionHistory: [...current.actionHistory, act.action],
        );
        final edge = SpotLineEdge(
          actor: actor,
          action: act.action,
          target: next,
          ev: act.ev,
        );
        current.edges.add(edge);
        current = next;
      }
    }

    if (spot.heroOptions.isNotEmpty) {
      for (final opt in spot.heroOptions) {
        final next = SpotLineNode(
          street: current.street,
          stack: current.stack,
          pot: current.pot,
          heroPosition: heroPos,
          actionHistory: [...current.actionHistory, opt],
        );
        final edge = SpotLineEdge(
          actor: 'hero',
          action: opt,
          target: next,
          correct: spot.correctAction != null
              ? opt.toLowerCase() == spot.correctAction!.toLowerCase()
              : null,
        );
        current.edges.add(edge);
      }
    }

    return SpotLineGraph(root: root);
  }
}
