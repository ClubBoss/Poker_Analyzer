import 'transition_lock_service.dart';
import 'board_manager_service.dart';

/// Snapshot of transition lock state.
class TransitionLockSnapshot {
  final bool isTransitioning;
  const TransitionLockSnapshot({required this.isTransitioning});
}

/// Handles undo/redo history for transition locks and manages
/// lock consistency during state restoration.
class TransitionHistoryService {
  TransitionHistoryService({
    required this.lockService,
    required this.boardManager,
  });

  final TransitionLockService lockService;
  final BoardManagerService boardManager;

  final List<TransitionLockSnapshot> _undoStack = [];
  final List<TransitionLockSnapshot> _redoStack = [];

  /// Whether transitions are currently locked or an undo/redo is in progress.
  bool get isLocked =>
      lockService.undoRedoTransitionLock || lockService.isLocked;

  TransitionLockSnapshot _currentSnapshot() =>
      TransitionLockSnapshot(isTransitioning: lockService.boardTransitioning);

  /// Record the current transition state.
  void recordSnapshot() {
    _undoStack.add(_currentSnapshot());
    _redoStack.clear();
  }

  /// Clear any stored history.
  void resetHistory() {
    _undoStack.clear();
    _redoStack.clear();
  }

  void _applySnapshot(TransitionLockSnapshot snap) {
    lockService.cancelBoardTransition();
    if (snap.isTransitioning) {
      boardManager.startBoardTransition();
    } else {
      lockService.boardTransitioning = false;
    }
  }

  void _restoreWithSnapshot(
    TransitionLockSnapshot snap,
    void Function() restore,
  ) {
    lockService.lock();
    try {
      restore();
      _applySnapshot(snap);
    } finally {
      lockService.unlock();
    }
  }

  /// Undo the last recorded transition applying [restore] afterwards.
  void undo(void Function() restore) {
    if (isLocked) return;
    if (_undoStack.isEmpty) return;
    final snap = _undoStack.removeLast();
    _redoStack.add(_currentSnapshot());
    _restoreWithSnapshot(snap, restore);
  }

  /// Redo the next transition applying [restore] afterwards.
  void redo(void Function() restore) {
    if (isLocked) return;
    if (_redoStack.isEmpty) return;
    final snap = _redoStack.removeLast();
    _undoStack.add(_currentSnapshot());
    _restoreWithSnapshot(snap, restore);
  }
}
