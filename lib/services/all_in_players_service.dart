import 'package:flutter/foundation.dart';

import '../models/action_entry.dart';
import '../models/saved_hand.dart';
import 'action_sync_service.dart';

/// Tracks players who have gone all-in during a hand.
class AllInPlayersService extends ChangeNotifier {
  final Set<int> _allInPlayers = {};

  ActionSyncService? _actionSync;
  VoidCallback? _listener;

  AllInPlayersService({ActionSyncService? actionSync}) {
    if (actionSync != null) {
      attach(actionSync);
    }
  }

  Set<int> get players => _allInPlayers;
  bool get isEmpty => _allInPlayers.isEmpty;

  bool isPlayerAllIn(int index) => _allInPlayers.contains(index);

  void reset() {
    if (_allInPlayers.isEmpty) return;
    _allInPlayers.clear();
    notifyListeners();
  }

  void add(int index) {
    if (_allInPlayers.add(index)) notifyListeners();
  }

  void remove(int index) {
    if (_allInPlayers.remove(index)) notifyListeners();
  }

  void restore(Iterable<int> indexes) {
    _allInPlayers
      ..clear()
      ..addAll(indexes);
    notifyListeners();
  }

  void recompute(List<ActionEntry> actions) {
    restore({
      for (final a in actions)
        if (a.action == 'all-in') a.playerIndex,
    });
  }

  void addFromAction(ActionEntry entry) {
    if (entry.action == 'all-in') add(entry.playerIndex);
  }

  void removeFromAction(ActionEntry entry, List<ActionEntry> remaining) {
    if (entry.action != 'all-in') return;
    final stillAllIn = remaining.any(
      (a) => a.playerIndex == entry.playerIndex && a.action == 'all-in',
    );
    if (!stillAllIn) remove(entry.playerIndex);
  }

  void editAction(
    ActionEntry oldEntry,
    ActionEntry newEntry,
    List<ActionEntry> actions,
  ) {
    removeFromAction(oldEntry, actions);
    addFromAction(newEntry);
  }

  List<int> toList() => List<int>.from(_allInPlayers);
  List<int>? toNullableList() => _allInPlayers.isEmpty ? null : toList();
  List<int>? toJson() => toNullableList();

  void restoreFromJson(List<dynamic>? json) {
    if (json == null) {
      reset();
    } else {
      restore(json.cast<int>());
    }
  }

  void restoreFromHand(SavedHand hand) {
    if (hand.allInPlayers != null) {
      restoreFromJson(hand.allInPlayers);
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
