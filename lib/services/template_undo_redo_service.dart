import "../models/v2/training_pack_spot.dart";
class UndoRedoService {
  final int limit;
  final List<List<TrainingPackSpot>> _undo = [];
  final List<List<TrainingPackSpot>> _redo = [];
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

  List<TrainingPackSpot> _clone(List<TrainingPackSpot> src) =>
      [for (final s in src) TrainingPackSpot.fromJson(s.toJson())];
}
