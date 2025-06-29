import '../models/table_state.dart';

class TableEditHistory {
  TableEditHistory._();
  static final TableEditHistory _instance = TableEditHistory._();
  factory TableEditHistory() => _instance;
  static TableEditHistory get instance => _instance;

  final List<TableState> _undo = [];
  final List<TableState> _redo = [];

  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  void push(TableState state) {
    _undo.add(state.copy());
    if (_undo.length > 20) _undo.removeAt(0);
    _redo.clear();
  }

  TableState? undo(TableState current) {
    if (_undo.isEmpty) return null;
    final state = _undo.removeLast();
    _redo.add(current.copy());
    return state;
  }

  TableState? redo(TableState current) {
    if (_redo.isEmpty) return null;
    final state = _redo.removeLast();
    _undo.add(current.copy());
    return state;
  }

  void clear() {
    _undo.clear();
    _redo.clear();
  }
}
