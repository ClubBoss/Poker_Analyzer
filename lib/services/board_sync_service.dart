import '../models/card_model.dart';
import 'action_sync_service.dart';
import 'player_manager_service.dart';

/// Handles board consistency and revealed card state.
class BoardSyncService {
  BoardSyncService({
    required PlayerManagerService playerManager,
    required ActionSyncService actionSync,
  })  : _playerManager = playerManager,
        _actionSync = actionSync;

  final PlayerManagerService _playerManager;
  final ActionSyncService _actionSync;

  static const List<int> stageCardCounts = [0, 3, 4, 5];

  final List<CardModel> revealedBoardCards = [];

  List<CardModel> get boardCards => _playerManager.boardCards;

  int get currentStreet => _actionSync.currentStreet;
  int get boardStreet => _actionSync.boardStreet;

  /// Update [_actionSync.boardStreet] based on the number of [boardCards].
  /// Returns true if the street changed.
  bool ensureBoardStreetConsistent() {
    final inferred = _inferBoardStreet();
    if (inferred != boardStreet) {
      _actionSync.setBoardStreet(inferred);
      _actionSync.changeStreet(inferred);
      return true;
    }
    return false;
  }

  /// Determine the board street based solely on the number of [boardCards].
  ///
  /// Exposed for components that need to infer the board stage without
  /// mutating analyzer state.
  int inferBoardStreet() => _inferBoardStreet();

  void updateRevealedBoardCards() {
    syncRevealState(revealStreet: currentStreet);
  }

  /// Synchronize [revealedBoardCards] for the given [revealStreet].
  ///
  /// When [showFullBoard] is true the board is shown up to [boardStreet]
  /// regardless of the current street.
  void syncRevealState(
      {required int revealStreet, bool showFullBoard = false}) {
    final street =
        (showFullBoard ? boardStreet : revealStreet).clamp(0, boardStreet);
    final visibleCount = stageCardCounts[street];
    revealedBoardCards
      ..clear()
      ..addAll(boardCards.take(visibleCount));
  }

  int _inferBoardStreet() {
    final count = boardCards.length;
    if (count >= stageCardCounts[3]) return 3;
    if (count >= stageCardCounts[2]) return 2;
    if (count >= stageCardCounts[1]) return 1;
    return 0;
  }

  bool isBoardStageComplete(int stage) {
    return boardCards.length >= stageCardCounts[stage];
  }
}
