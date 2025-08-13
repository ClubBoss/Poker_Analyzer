import 'package:poker_analyzer/models/saved_hand.dart';
import 'package:poker_analyzer/models/training_spot.dart';
import 'package:poker_analyzer/models/player_model.dart';

/// Generates [TrainingSpot]s from [SavedHand] instances.
class TrainingGenerator {
  /// Converts [hand] into a [TrainingSpot] preserving tournament metadata.
  TrainingSpot generateFromSavedHand(SavedHand hand) {
    return TrainingSpot(
      playerCards: [
        for (final list in hand.playerCards) List.of(list),
      ],
      boardCards: List.of(hand.boardCards),
      actions: List.of(hand.actions),
      heroIndex: hand.heroIndex,
      numberOfPlayers: hand.numberOfPlayers,
      playerTypes: [
        for (int i = 0; i < hand.numberOfPlayers; i++)
          hand.playerTypes?[i] ?? PlayerType.unknown,
      ],
      positions: [
        for (int i = 0; i < hand.numberOfPlayers; i++)
          hand.playerPositions[i] ?? '',
      ],
      stacks: [
        for (int i = 0; i < hand.numberOfPlayers; i++) hand.stackSizes[i] ?? 0,
      ],
      equities: null,
      tournamentId: hand.tournamentId,
      buyIn: hand.buyIn,
      totalPrizePool: hand.totalPrizePool,
      numberOfEntrants: hand.numberOfEntrants,
      gameType: hand.gameType,
      anteBb: hand.anteBb,
      category: hand.category,
      tags: List<String>.from(hand.tags),
      actionHistory: null,
      difficulty: 3,
      rating: 0,
    );
  }
}
