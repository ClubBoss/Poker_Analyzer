import 'package:flutter/foundation.dart';

import '../models/player_zone_action_entry.dart';

class ActionSyncService extends ChangeNotifier {
  final Map<String, List<ActionEntry>> actions = {
    'Preflop': [],
    'Flop': [],
    'Turn': [],
    'River': [],
  };

  void addOrUpdate(ActionEntry entry) {
    final list = actions[entry.street]!;
    final index = list.indexWhere((e) => e.playerName == entry.playerName);
    if (index >= 0) {
      list[index] = entry;
    } else {
      list.add(entry);
    }
    notifyListeners();
  }

  /// Removes the most recently added action for the given street, if any.
  void undoLastAction(String street) {
    final list = actions[street];
    if (list != null && list.isNotEmpty) {
      list.removeLast();
      notifyListeners();
    }
  }

  /// Clears all actions for the specified street.
  void clearStreet(String street) {
    final list = actions[street];
    if (list != null && list.isNotEmpty) {
      list.clear();
      notifyListeners();
    }
  }
}
