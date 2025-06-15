import 'package:flutter/foundation.dart';

import '../models/action_entry.dart';
import 'action_sync_service.dart';

/// Manages the set of folded players and provides helpers to update it.
class FoldedPlayersService {
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

  void attach(ActionSyncService actionSync) {
    _actionSync?.removeListener(_listener!);
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

  void dispose() => detach();
}
