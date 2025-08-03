import 'package:flutter/foundation.dart';

import '../models/player_model.dart';

/// Controller responsible for managing the state of the poker analyzer.
///
/// Moving the mutable state out of the UI widgets allows the view layer to
/// remain declarative and focused purely on presentation. The controller can
/// later be expanded with more complex logic and persistence as the feature
/// grows.
class PokerAnalyzerController extends ChangeNotifier {
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

  /// Toggles [debugMode] and notifies listeners.
  void toggleDebug() {
    debugMode = !debugMode;
    notifyListeners();
  }
}

