import 'package:flutter/foundation.dart';

import '../models/player_zone_action_entry.dart';

class ActionSyncService extends ChangeNotifier {
  final Map<String, List<ActionEntry>> actions = {
    'Preflop': [],
    'Flop': [],
    'Turn': [],
    'River': [],
  };

  final List<ActionEntry> _history = [];

  void addOrUpdate(ActionEntry entry) {
    final list = actions[entry.street]!;
    final index = list.indexWhere((e) => e.playerName == entry.playerName);
    if (index >= 0) {
      list[index] = entry;
    } else {
      list.add(entry);
      _history.add(entry);
    }
    notifyListeners();
  }

  /// Removes the most recently added action for the given street, if any.
  void undoLastAction(String street) {
    final list = actions[street];
    if (list != null && list.isNotEmpty) {
      final removed = list.removeLast();
      _history.remove(removed);
      notifyListeners();
    }
  }

  /// Removes the last added action across all streets, if any.
  void undoLastGlobal() {
    if (_history.isNotEmpty) {
      final last = _history.removeLast();
      final list = actions[last.street];
      list?.remove(last);
      notifyListeners();
    }
  }

  /// Clears all actions for the specified street.
  void clearStreet(String street) {
    final list = actions[street];
    if (list != null && list.isNotEmpty) {
      for (final a in list) {
        _history.remove(a);
      }
      list.clear();
      notifyListeners();
    }
  }
}
