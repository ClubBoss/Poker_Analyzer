import '../models/action_entry.dart';

/// Manages action tags for each player, such as the last action and amount.
class ActionTagService {
  final Map<int, String?> _tags = {};

  /// Current map of action tags per player.
  Map<int, String?> get tags => _tags;

  /// Returns the tag for [playerIndex] or `null` if none.
  String? getTag(int playerIndex) => _tags[playerIndex];

  /// Clears all action tags.
  void clear() => _tags.clear();

  /// Restores tags from a saved map.
  void restore(Map<int, String?>? saved) {
    _tags
      ..clear()
      ..addAll(saved ?? {});
  }

  /// Updates the tag for a newly added or edited [entry].
  void updateForAction(ActionEntry entry) {
    _tags[entry.playerIndex] =
        '${entry.action}${entry.amount != null ? ' ${entry.amount}' : ''}';
  }

  /// Recomputes the tag for [playerIndex] after an action was removed.
  void updateAfterActionRemoval(int playerIndex, List<ActionEntry> actions) {
    try {
      final last = actions.lastWhere((a) => a.playerIndex == playerIndex);
      updateForAction(last);
    } catch (_) {
      _tags.remove(playerIndex);
    }
  }

  /// Shifts tags when a player at [index] is removed from a table of
  /// [numberOfPlayers] players.
  void shiftAfterPlayerRemoval(int index, int numberOfPlayers) {
    for (int i = index; i < numberOfPlayers - 1; i++) {
      _tags[i] = _tags[i + 1];
    }
    _tags.remove(numberOfPlayers - 1);
  }

  /// Removes the tag for [playerIndex].
  void removeTag(int playerIndex) => _tags.remove(playerIndex);
}
