import '../models/action_entry.dart';

/// Manages the set of folded players and provides helpers to update it.
class FoldedPlayersService {
  final Set<int> _foldedPlayers = {};

  Set<int> get players => _foldedPlayers;
  bool get isEmpty => _foldedPlayers.isEmpty;

  bool contains(int index) => _foldedPlayers.contains(index);

  void clear() {
    _foldedPlayers.clear();
  }

  void add(int index) {
    _foldedPlayers.add(index);
  }

  void setFrom(Iterable<int> indexes) {
    _foldedPlayers
      ..clear()
      ..addAll(indexes);
  }

  /// Recompute folded players from the list of [actions].
  void recompute(List<ActionEntry> actions) {
    _foldedPlayers
      ..clear()
      ..addAll({
        for (final a in actions)
          if (a.action == 'fold') a.playerIndex
      });
  }
}
