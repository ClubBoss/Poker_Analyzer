import "../models/v2/hero_position.dart";
import '../models/v2/training_pack_preset.dart';
import '../models/training_spot.dart';
import '../models/card_model.dart';
import '../models/action_entry.dart';
import '../models/player_model.dart';
import '../models/game_type.dart';

class TrainingPackPresetRepository {
  static Future<List<TrainingPackPreset>> getAll() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      TrainingPackPreset(
        id: 'beginner_push_fold',
        name: 'Beginner Push/Fold',
        description: 'Basic 10BB spots without ante',
        gameType: GameType.tournament,
        heroBbStack: 10,
        playerStacksBb: const [10, 10],
        heroPos: HeroPosition.sb,
        spotCount: 3,
        spots: [
          TrainingSpot(
            playerCards: [
              [CardModel(rank: 'A', suit: 'h'), CardModel(rank: '8', suit: 'h')],
              <CardModel>[],
            ],
            boardCards: const [],
            actions: [
              ActionEntry(0, 0, 'push', amount: 10),
              ActionEntry(0, 1, 'fold'),
            ],
            heroIndex: 0,
            numberOfPlayers: 2,
            playerTypes: [PlayerType.unknown, PlayerType.unknown],
            positions: ['SB', 'BB'],
            stacks: [10, 10],
            tags: const ['pushfold'],
          ),
          TrainingSpot(
            playerCards: [
              [CardModel(rank: 'K', suit: 'd'), CardModel(rank: 'Q', suit: 'd')],
              [CardModel(rank: '5', suit: 's'), CardModel(rank: '5', suit: 'c')],
            ],
            boardCards: const [],
            actions: [
              ActionEntry(0, 0, 'push', amount: 10),
              ActionEntry(0, 1, 'call', amount: 10),
            ],
            heroIndex: 0,
            numberOfPlayers: 2,
            playerTypes: [PlayerType.unknown, PlayerType.unknown],
            positions: ['SB', 'BB'],
            stacks: [10, 10],
            tags: const ['pushfold'],
          ),
          TrainingSpot(
            playerCards: [
              [CardModel(rank: 'A', suit: 's'), CardModel(rank: '2', suit: 's')],
              <CardModel>[],
            ],
            boardCards: const [],
            actions: [
              ActionEntry(0, 0, 'push', amount: 10),
              ActionEntry(0, 1, 'fold'),
            ],
            heroIndex: 0,
            numberOfPlayers: 2,
            playerTypes: [PlayerType.unknown, PlayerType.unknown],
            positions: ['BTN', 'BB'],
            stacks: [10, 10],
            tags: const ['pushfold'],
          ),
        ],
      ),
    ];
  }
}
