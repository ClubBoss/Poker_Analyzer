import 'package:flutter/foundation.dart';

import '../models/action_entry.dart';
import '../models/player_zone_action_entry.dart' as pz;
import '../models/card_model.dart';

class ActionSyncService extends ChangeNotifier {
  int currentStreet = 0;
  int boardStreet = 0;
  int playbackIndex = 0;
  final Set<int> expandedHistoryStreets = {};
  final Map<String, List<pz.ActionEntry>> actions = {
    'Preflop': [],
    'Flop': [],
    'Turn': [],
    'River': [],
  };

  final List<pz.ActionEntry> _history = [];

  void addOrUpdate(pz.ActionEntry entry) {
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
  void updateAction(String street, int index, pz.ActionEntry newEntry) {
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

  void changeStreet(int street) {
    currentStreet = street;
    notifyListeners();
  }

  void setBoardStreet(int street) {
    boardStreet = street;
    if (currentStreet > boardStreet) {
      currentStreet = boardStreet;
    }
    notifyListeners();
  }

  void updatePlaybackIndex(int index) {
    playbackIndex = index;
  }

  ActionSnapshot buildSnapshot(List<CardModel> board) {
    return ActionSnapshot(
      street: currentStreet,
      boardStreet: boardStreet,
      board: List<CardModel>.from(board),
      playbackIndex: playbackIndex,
      expandedStreets: Set<int>.from(expandedHistoryStreets),
    );
  }

  void restoreSnapshot(ActionSnapshot snap) {
    currentStreet = snap.street;
    boardStreet = snap.boardStreet;
    playbackIndex = snap.playbackIndex;
    expandedHistoryStreets
      ..clear()
      ..addAll(snap.expandedStreets);
    notifyListeners();
  }

  void addExpandedStreet(int street) {
    expandedHistoryStreets.add(street);
    notifyListeners();
  }

  void removeExpandedStreet(int street) {
    expandedHistoryStreets.remove(street);
    notifyListeners();
  }

  // ----- PokerAnalyzer synchronization -----

  final List<ActionEntry> analyzerActions = [];
  final List<ActionHistoryEntry> _undoStack = [];
  final List<ActionHistoryEntry> _redoStack = [];
  final List<ActionSnapshot> _undoSnapshots = [];
  final List<ActionSnapshot> _redoSnapshots = [];

  void setAnalyzerActions(List<ActionEntry> entries) {
    analyzerActions
      ..clear()
      ..addAll(entries);
    _undoStack.clear();
    _redoStack.clear();
    _undoSnapshots.clear();
    _redoSnapshots.clear();
    notifyListeners();
  }

  void clearAnalyzerActions() {
    analyzerActions.clear();
    _undoStack.clear();
    _redoStack.clear();
    _undoSnapshots.clear();
    _redoSnapshots.clear();
    notifyListeners();
  }

  void recordSnapshot(ActionSnapshot snap) {
    _undoSnapshots.add(snap);
    _redoSnapshots.clear();
  }

  void addAnalyzerAction(ActionEntry entry,
      {int? index, bool recordHistory = true, required int prevStreet, required int newStreet}) {
    final insertIndex = index ?? analyzerActions.length;
    if (index != null) {
      analyzerActions.insert(index, entry);
    } else {
      analyzerActions.add(entry);
    }
    if (recordHistory) {
      _undoStack.add(ActionHistoryEntry(ActionChangeType.add, insertIndex,
          newEntry: entry, prevStreet: prevStreet, newStreet: newStreet));
      _redoStack.clear();
    }
    notifyListeners();
  }

  void updateAnalyzerAction(int index, ActionEntry entry,
      {bool recordHistory = true, required int street}) {
    final previous = analyzerActions[index];
    analyzerActions[index] = entry;
    if (recordHistory) {
      _undoStack.add(ActionHistoryEntry(ActionChangeType.edit, index,
          oldEntry: previous,
          newEntry: entry,
          prevStreet: street,
          newStreet: street));
      _redoStack.clear();
    }
    notifyListeners();
  }

  void deleteAnalyzerAction(int index,
      {bool recordHistory = true, required int street}) {
    final removed = analyzerActions.removeAt(index);
    if (recordHistory) {
      _undoStack.add(ActionHistoryEntry(ActionChangeType.delete, index,
          oldEntry: removed,
          prevStreet: street,
          newStreet: street));
      _redoStack.clear();
    }
    notifyListeners();
  }

  UndoRedoResult undo(ActionSnapshot currentSnapshot) {
    if (_undoStack.isEmpty) {
      if (_undoSnapshots.isEmpty) {
        return UndoRedoResult(null, null);
      }
      final snap = _undoSnapshots.removeLast();
      _redoSnapshots.add(currentSnapshot);
      return UndoRedoResult(null, snap);
    }
    final op = _undoStack.removeLast();
    ActionSnapshot? snap;
    if (_undoSnapshots.isNotEmpty) {
      snap = _undoSnapshots.removeLast();
      _redoSnapshots.add(currentSnapshot);
    }
    switch (op.type) {
      case ActionChangeType.add:
        analyzerActions.removeAt(op.index);
        break;
      case ActionChangeType.edit:
        analyzerActions[op.index] = op.oldEntry!;
        break;
      case ActionChangeType.delete:
        analyzerActions.insert(op.index, op.oldEntry!);
        break;
    }
    _redoStack.add(op);
    notifyListeners();
    return UndoRedoResult(op, snap);
  }

  UndoRedoResult redo(ActionSnapshot currentSnapshot) {
    if (_redoStack.isEmpty) {
      if (_redoSnapshots.isEmpty) {
        return UndoRedoResult(null, null);
      }
      final snap = _redoSnapshots.removeLast();
      _undoSnapshots.add(currentSnapshot);
      return UndoRedoResult(null, snap);
    }
    final op = _redoStack.removeLast();
    ActionSnapshot? snap;
    if (_redoSnapshots.isNotEmpty) {
      snap = _redoSnapshots.removeLast();
      _undoSnapshots.add(currentSnapshot);
    }
    switch (op.type) {
      case ActionChangeType.add:
        analyzerActions.insert(op.index, op.newEntry!);
        break;
      case ActionChangeType.edit:
        analyzerActions[op.index] = op.newEntry!;
        break;
      case ActionChangeType.delete:
        analyzerActions.removeAt(op.index);
        break;
    }
    _undoStack.add(op);
    notifyListeners();
    return UndoRedoResult(op, snap);
  }
}

enum ActionChangeType { add, edit, delete }

class ActionHistoryEntry {
  final ActionChangeType type;
  final int index;
  final ActionEntry? oldEntry;
  final ActionEntry? newEntry;
  final int prevStreet;
  final int newStreet;

  ActionHistoryEntry(
    this.type,
    this.index, {
    this.oldEntry,
    this.newEntry,
    required this.prevStreet,
    required this.newStreet,
  });
}

class ActionSnapshot {
  final int street;
  final int boardStreet;
  final List<CardModel> board;
  final int playbackIndex;
  final Set<int> expandedStreets;

  ActionSnapshot({
    required this.street,
    required this.boardStreet,
    required this.board,
    required this.playbackIndex,
    required this.expandedStreets,
  });
}

class UndoRedoResult {
  final ActionHistoryEntry? entry;
  final ActionSnapshot? snapshot;

  UndoRedoResult(this.entry, this.snapshot);
}
