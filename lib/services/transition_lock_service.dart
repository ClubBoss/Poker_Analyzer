import 'package:flutter/foundation.dart';

/// Centralizes board and undo/redo transition locks.
class TransitionLockService extends ChangeNotifier {
  bool _boardTransitioning = false;
  bool _undoRedoTransitionLock = false;

  bool get boardTransitioning => _boardTransitioning;
  bool get undoRedoTransitionLock => _undoRedoTransitionLock;

  set boardTransitioning(bool value) {
    if (_boardTransitioning == value) return;
    _boardTransitioning = value;
    notifyListeners();
  }

  set undoRedoTransitionLock(bool value) {
    if (_undoRedoTransitionLock == value) return;
    _undoRedoTransitionLock = value;
    notifyListeners();
  }
}

