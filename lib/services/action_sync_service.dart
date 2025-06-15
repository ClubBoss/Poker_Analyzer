import 'package:flutter/foundation.dart';

import '../models/player_zone_action_entry.dart';
import '../models/action_entry.dart' as an;

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

  /// Updates an existing action entry at the given index for the street.
  void updateAction(String street, int index, ActionEntry newEntry) {
    final list = actions[street];
    if (list == null || index < 0 || index >= list.length) return;
    list[index] = newEntry;
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

  // --- Poker analyzer actions ---
  final List<an.ActionEntry> analyzerActions = [];
  final List<List<an.ActionEntry>> _undoAnalyzer = [];
  final List<List<an.ActionEntry>> _redoAnalyzer = [];

  void _pushUndo() {
    _undoAnalyzer.add([for (final a in analyzerActions) _clone(a)]);
    if (_undoAnalyzer.length > 100) _undoAnalyzer.removeAt(0);
  }

  an.ActionEntry _clone(an.ActionEntry a) => an.ActionEntry(
        a.street,
        a.playerIndex,
        a.action,
        amount: a.amount,
        generated: a.generated,
        timestamp: a.timestamp,
      );

  void addAnalyzerAction(an.ActionEntry entry, {int? index}) {
    _pushUndo();
    if (index == null) {
      analyzerActions.add(entry);
    } else {
      analyzerActions.insert(index, entry);
    }
    _redoAnalyzer.clear();
    notifyListeners();
  }

  void updateAnalyzerAction(int index, an.ActionEntry entry) {
    if (index < 0 || index >= analyzerActions.length) return;
    _pushUndo();
    analyzerActions[index] = entry;
    _redoAnalyzer.clear();
    notifyListeners();
  }

  void deleteAnalyzerAction(int index) {
    if (index < 0 || index >= analyzerActions.length) return;
    _pushUndo();
    analyzerActions.removeAt(index);
    _redoAnalyzer.clear();
    notifyListeners();
  }

  bool undoAnalyzerAction() {
    if (_undoAnalyzer.isEmpty) return false;
    _redoAnalyzer.add([for (final a in analyzerActions) _clone(a)]);
    final snap = _undoAnalyzer.removeLast();
    analyzerActions
      ..clear()
      ..addAll(snap);
    notifyListeners();
    return true;
  }

  bool redoAnalyzerAction() {
    if (_redoAnalyzer.isEmpty) return false;
    _undoAnalyzer.add([for (final a in analyzerActions) _clone(a)]);
    final snap = _redoAnalyzer.removeLast();
    analyzerActions
      ..clear()
      ..addAll(snap);
    notifyListeners();
    return true;
  }
}
