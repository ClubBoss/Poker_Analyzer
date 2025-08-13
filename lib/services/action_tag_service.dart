import '../models/action_entry.dart';
import '../models/saved_hand.dart';

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

  /// Recomputes all tags based on [actions].
  void recompute(List<ActionEntry> actions) {
    _tags.clear();
    for (final a in actions) {
      _tags[a.playerIndex] =
          '${a.action}${a.amount != null ? ' ${a.amount}' : ''}';
    }
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

  /// Assigns [tag] to the player at [playerIndex].
  void setTag(int playerIndex, String? tag) => _tags[playerIndex] = tag;

  /// Serializes tags to a JSON-friendly map.
  Map<String, String?> toJson() =>
      {for (final e in _tags.entries) e.key.toString(): e.value};

  /// Restores tags from a JSON map produced by [toJson].
  void restoreFromJson(Map<String, dynamic>? json) {
    if (json == null) {
      clear();
      return;
    }
    _tags
      ..clear()
      ..addAll(
          {for (final e in json.entries) int.parse(e.key): e.value as String?});
  }

  /// Returns a copy of the current tags map.
  Map<int, String?> toMap() => Map<int, String?>.from(_tags);

  /// Returns `null` when no tags are present, otherwise a copy of the map.
  Map<int, String?>? toNullableMap() => _tags.isEmpty ? null : toMap();

  /// Restores tags from [hand], falling back to recomputing from actions
  /// when the saved map is absent.
  void restoreFromHand(SavedHand hand) {
    if (hand.actionTags != null) {
      restore(hand.actionTags);
    } else {
      recompute(hand.actions);
    }
  }
}
