import 'package:flutter/foundation.dart';

import '../models/action_entry.dart';
import '../models/saved_hand.dart';
import 'action_sync_service.dart';

/// Manages the set of folded players and provides helpers to update it.
class FoldedPlayersService extends ChangeNotifier {
  final Set<int> _foldedPlayers = {};

  ActionSyncService? _actionSync;
  VoidCallback? _listener;

  FoldedPlayersService({ActionSyncService? actionSync}) {
    if (actionSync != null) {
      attach(actionSync);
    }
  }

  Set<int> get players => _foldedPlayers;
  bool get isEmpty => _foldedPlayers.isEmpty;

  /// Returns `true` if the player at [index] has folded.
  bool isPlayerFolded(int index) => _foldedPlayers.contains(index);

  /// Reset all folded players.
  void reset() {
    if (_foldedPlayers.isEmpty) return;
    _foldedPlayers.clear();
    notifyListeners();
  }

  /// Mark [index] as folded.
  void add(int index) {
    if (_foldedPlayers.add(index)) notifyListeners();
  }

  /// Unmark [index] as folded.
  void remove(int index) {
    if (_foldedPlayers.remove(index)) notifyListeners();
  }

  /// Restore from a list of folded player indexes.
  void restore(Iterable<int> indexes) {
    _foldedPlayers
      ..clear()
      ..addAll(indexes);
    notifyListeners();
  }

  /// Recompute folded players from the list of [actions].
  void recompute(List<ActionEntry> actions) {
    restore({
      for (final a in actions)
        if (a.action == 'fold') a.playerIndex
    });
  }

  /// Update folded state after adding [entry].
  void addFromAction(ActionEntry entry) {
    if (entry.action == 'fold') {
      add(entry.playerIndex);
    }
  }

  /// Update folded state after removing [entry].
  void removeFromAction(ActionEntry entry, List<ActionEntry> remaining) {
    if (entry.action != 'fold') return;
    final stillFolded = remaining
        .any((a) => a.playerIndex == entry.playerIndex && a.action == 'fold');
    if (!stillFolded) remove(entry.playerIndex);
  }

  /// Update folded state after editing an action.
  void editAction(
      ActionEntry oldEntry, ActionEntry newEntry, List<ActionEntry> actions) {
    removeFromAction(oldEntry, actions);
    addFromAction(newEntry);
  }

  /// Returns the list of folded player indexes.
  List<int> toList() => List<int>.from(_foldedPlayers);

  /// Returns `null` when no players have folded, otherwise a copy of the list.
  List<int>? toNullableList() => _foldedPlayers.isEmpty ? null : toList();

  /// Returns a JSON-compatible list of folded player indexes, or `null` if none.
  List<int>? toJson() => toNullableList();

  /// Restores folded players from a list produced by [toJson].
  void restoreFromJson(List<dynamic>? json) {
    if (json == null) {
      reset();
    } else {
      restore(json.cast<int>());
    }
  }

  /// Restores folded players from [hand], recomputing from actions when
  /// no folded player list is present.
  void restoreFromHand(SavedHand hand) {
    if (hand.foldedPlayers != null) {
      restoreFromJson(hand.foldedPlayers);
    } else {
      recompute(hand.actions);
    }
  }

  void attach(ActionSyncService actionSync) {
    _actionSync?.removeListener(_listener ?? () {});
    _actionSync = actionSync;
    _listener = () => recompute(_actionSync!.analyzerActions);
    _actionSync!.addListener(_listener!);
    recompute(_actionSync!.analyzerActions);
  }

  void detach() {
    if (_actionSync != null && _listener != null) {
      _actionSync!.removeListener(_listener!);
      _listener = null;
      _actionSync = null;
    }
  }

  @override
  void dispose() => detach();
}
