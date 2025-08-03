import 'package:flutter/foundation.dart';

import '../models/player_model.dart';

/// Service holding the core state for the [PokerAnalyzerScreen].
///
/// Moving this logic out of the screen allows the UI widgets to remain
/// focused on composition. The service can later be expanded with additional
/// game logic and exposed through providers.
class PokerAnalyzerService extends ChangeNotifier {
  /// Number of players at the table.
  int numberOfPlayers = 2;

  /// Mapping from player index to their table position (e.g. "BTN").
  final Map<int, String> playerPositions = {};

  /// Player type metadata keyed by player index.
  final Map<int, PlayerType> playerTypes = {};

  /// List of current players.
  final List<PlayerModel> players = [];

  /// Flag controlling display of debug information in the overlay.
  bool debugMode = false;

  /// Updates the number of players and notifies listeners.
  void setNumberOfPlayers(int count) {
    if (count == numberOfPlayers) return;
    numberOfPlayers = count;
    notifyListeners();
  }

  /// Toggles the debug mode flag.
  void toggleDebugMode() {
    debugMode = !debugMode;
    notifyListeners();
  }
}

