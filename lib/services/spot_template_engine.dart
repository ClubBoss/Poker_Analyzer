import 'package:uuid/uuid.dart';
import '../models/v2/training_pack_template.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hand_data.dart';
import '../models/v2/hero_position.dart';
import '../models/action_entry.dart';
import '../models/game_type.dart';
import 'evaluation_executor_service.dart';

class SpotTemplateEngine {
  final EvaluationExecutorService executor;
  SpotTemplateEngine({EvaluationExecutorService? executor})
      : executor = executor ?? EvaluationExecutorService();

  Future<TrainingPackTemplate> generate({
    required HeroPosition heroPosition,
    required HeroPosition villainPosition,
    required List<int> stackRange,
    required String actionType,
    bool withIcm = false,
  }) async {
    final uuid = const Uuid();
    final spots = <TrainingPackSpot>[];
    for (final stack in stackRange) {
      final actions = <int, List<ActionEntry>>{
        0: _actions(actionType, stack)
      };
      if (actions[0] == null) continue;
      final hand = HandData(
        position: heroPosition,
        heroIndex: 0,
        playerCount: 2,
        stacks: {
          '0': stack.toDouble(),
          '1': stack.toDouble(),
        },
        actions: actions,
      );
      spots.add(TrainingPackSpot(id: uuid.v4(), hand: hand));
    }
    final template = TrainingPackTemplate(
      id: uuid.v4(),
      name: 'Template',
      gameType: GameType.tournament,
      spots: spots,
      heroBbStack: stackRange.isNotEmpty ? stackRange.first : 0,
      playerStacksBb: stackRange.isNotEmpty
          ? [stackRange.first, stackRange.first]
          : const [0, 0],
      heroPos: heroPosition,
      spotCount: spots.length,
    );
    await executor.bulkEvaluate(spots,
        template: template, anteBb: 0, withIcm: withIcm);
    return template;
  }

  List<ActionEntry>? _actions(String type, int stack) {
    switch (type) {
      case 'push':
        return [
          ActionEntry(0, 0, 'push', amount: stack.toDouble()),
          ActionEntry(0, 1, 'fold'),
        ];
      case 'callPush':
        return [
          ActionEntry(0, 1, 'push', amount: stack.toDouble()),
          ActionEntry(0, 0, 'call', amount: stack.toDouble()),
        ];
      case 'minraiseFold':
        return [
          ActionEntry(0, 0, 'raise', amount: 2),
          ActionEntry(0, 1, 'push', amount: stack.toDouble()),
          ActionEntry(0, 0, 'fold'),
        ];
    }
    return null;
  }
}
