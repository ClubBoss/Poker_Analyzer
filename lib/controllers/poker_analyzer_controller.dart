import 'dart:collection';

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
  int _numberOfPlayers = 2;

  /// Mapping from player index to their table position (e.g. "BTN").
  final Map<int, String> _playerPositions = {};

  /// Player type metadata keyed by player index.
  final Map<int, PlayerType> _playerTypes = {};

  /// List of current players.
  final List<PlayerModel> _players = [];

  /// Flag controlling display of debug information in the overlay.
  bool _debugMode = false;

  int get numberOfPlayers => _numberOfPlayers;
  set numberOfPlayers(int value) {
    if (_numberOfPlayers == value) return;
    _numberOfPlayers = value;
    notifyListeners();
  }

  Map<int, String> get playerPositions => Map.unmodifiable(_playerPositions);
  void setPlayerPosition(int index, String position) {
    _playerPositions[index] = position;
    notifyListeners();
  }

  Map<int, PlayerType> get playerTypes => Map.unmodifiable(_playerTypes);
  void setPlayerType(int index, PlayerType type) {
    _playerTypes[index] = type;
    notifyListeners();
  }

  List<PlayerModel> get players => List.unmodifiable(_players);
  void addPlayer(PlayerModel player) {
    _players.add(player);
    notifyListeners();
  }

  void removePlayer(PlayerModel player) {
    _players.remove(player);
    notifyListeners();
  }

  bool get debugMode => _debugMode;

  /// Toggles [debugMode] and notifies listeners.
  void toggleDebug() {
    _debugMode = !_debugMode;
    notifyListeners();
  }

  /// Convenience getter for the current player count.
  int get playerCount => _players.length;
}

