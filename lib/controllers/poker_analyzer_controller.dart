import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/player_model.dart';
import '../models/training_spot.dart';

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

  late final UnmodifiableListView<PlayerModel> _unmodifiablePlayers =
      UnmodifiableListView(_players);

  /// Flag controlling display of debug information in the overlay.
  bool _debugMode = false;

  void _update(VoidCallback action) {
    action();
    notifyListeners();
  }

  set numberOfPlayers(int value) {
    if (_numberOfPlayers == value) return;
    _update(() {
      _numberOfPlayers = value;
    });
  }

  void setPlayerPosition(int index, String position) {
    final current = _playerPositions[index];
    if (current == position) return;
    _update(() {
      _playerPositions[index] = position;
    });
  }

  Map<int, PlayerType> get playerTypes => UnmodifiableMapView(_playerTypes);
  void setPlayerType(int index, PlayerType type) {
    final current = _playerTypes[index];
    if (current == type) return;
    _update(() {
      _playerTypes[index] = type;
    });
  }

  List<PlayerModel> get players => _unmodifiablePlayers;
  void addPlayer(PlayerModel player) {
    _update(() {
      _players.add(player);
    });
  }

  void removePlayer(PlayerModel player) {
    _update(() {
      _players.remove(player);
    });
  }

  /// Loads a new [TrainingSpot] into the controller, replacing any existing
  /// table state.
  void loadSpot(TrainingSpot spot) {
    _update(() {
      final playerCount = [
        spot.numberOfPlayers,
        spot.positions.length,
        spot.playerTypes.length,
        spot.stacks.length,
      ].reduce(math.min);

      _numberOfPlayers = playerCount;
      _playerPositions
        ..clear()
        ..addAll({
          for (var i = 0; i < playerCount; i++) i: spot.positions[i]
        });
      _playerTypes
        ..clear()
        ..addAll({
          for (var i = 0; i < playerCount; i++) i: spot.playerTypes[i]
        });
      _players
        ..clear()
        ..addAll([
          for (var i = 0; i < playerCount; i++)
            PlayerModel(
              name: 'Player ${i + 1}',
              type: spot.playerTypes[i],
              stack: spot.stacks[i],
            )
        ]);
    });
  }

  bool get debugMode => _debugMode;

  /// Toggles [debugMode] and notifies listeners.
  void toggleDebug() {
    _update(() {
      _debugMode = !_debugMode;
    });
  }

  /// Convenience getter for the current player count.
  int get playerCount => _players.length;

  /// Public getters used by tests/consumers.
  int get numberOfPlayers => _numberOfPlayers;
  Map<int, String> get playerPositions => UnmodifiableMapView(_playerPositions);
}
