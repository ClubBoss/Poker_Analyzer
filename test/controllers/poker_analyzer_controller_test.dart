import 'package:test/test.dart';
import 'package:poker_analyzer/controllers/poker_analyzer_controller.dart';
import 'package:poker_analyzer/models/action_entry.dart';
import 'package:poker_analyzer/models/card_model.dart';
import 'package:poker_analyzer/models/player_model.dart';
import 'package:poker_analyzer/models/training_spot.dart';

void main() {
  test('loadSpot clamps inputs and populates state', () {
    final controller = PokerAnalyzerController();

    final spot = TrainingSpot(
      playerCards: List.generate(4, (_) => <CardModel>[]),
      boardCards: <CardModel>[],
      actions: <ActionEntry>[],
      heroIndex: 0,
      numberOfPlayers: 4,
      playerTypes: const [PlayerType.shark, PlayerType.fish, PlayerType.nit],
      positions: const ['BTN', 'SB'],
      stacks: const [100, 200, 300, 400],
    );

    controller.loadSpot(spot);

    expect(controller.numberOfPlayers, 2);
    expect(controller.playerPositions, {0: 'BTN', 1: 'SB'});
    expect(controller.playerTypes, {0: PlayerType.shark, 1: PlayerType.fish});
    expect(controller.players.length, 2);
    expect(controller.players.map((p) => p.stack).toList(), [100, 200]);
    expect(controller.players.map((p) => p.type).toList(), [
      PlayerType.shark,
      PlayerType.fish,
    ]);
  });
}
