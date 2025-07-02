import "../models/v2/training_pack_spot.dart";

class ChangeEntry {
  final String action;
  final String title;
  final DateTime time;
  ChangeEntry(this.action, this.title) : time = DateTime.now();
}

class UndoRedoService {
  final int limit;
  final List<List<TrainingPackSpot>> _undo = [];
  final List<List<TrainingPackSpot>> _redo = [];
  final List<ChangeEntry> _events = [];
  UndoRedoService({this.limit = 30});

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void record(List<TrainingPackSpot> spots) {
    _undo.add(_clone(spots));
    if (_undo.length > limit) _undo.removeAt(0);
    _redo.clear();
  }

  List<TrainingPackSpot>? undo(List<TrainingPackSpot> current) {
    if (_undo.isEmpty) return null;
    final snap = _undo.removeLast();
    _redo.add(_clone(current));
    return snap;
  }

  List<TrainingPackSpot>? redo(List<TrainingPackSpot> current) {
    if (_redo.isEmpty) return null;
    final snap = _redo.removeLast();
    _undo.add(_clone(current));
    return snap;
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }

  void log(String action, String title) {
    _events.add(ChangeEntry(action, title));
    if (_events.length > 10) _events.removeAt(0);
  }

  List<ChangeEntry> get history => List.unmodifiable(_events.reversed);

  List<TrainingPackSpot> _clone(List<TrainingPackSpot> src) =>
      [for (final s in src) TrainingPackSpot.fromJson(s.toJson())];
}
