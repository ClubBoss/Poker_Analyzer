import "dart:async";
import "package:flutter/widgets.dart";

/// Coordinates board transition locking across services and widgets.
class TransitionLockService {
  bool boardTransitioning = false;
  bool undoRedoTransitionLock = false;

  Timer? _transitionTimer;

  bool get isLocked => boardTransitioning;

  /// Execute [fn] inside `setState` if the transition lock allows it.
  void safeSetState(
    State state,
    VoidCallback fn, {
    bool ignoreTransitionLock = false,
  }) {
    if (!state.mounted) return;
    if (boardTransitioning && !ignoreTransitionLock) return;
    state.setState(fn);
  }

  /// Start a board transition lock for [duration].
  void startBoardTransition(Duration duration, [VoidCallback? onComplete]) {
    _transitionTimer?.cancel();
    boardTransitioning = true;
    undoRedoTransitionLock = true;
    _transitionTimer = Timer(duration, () {
      boardTransitioning = false;
      undoRedoTransitionLock = false;
      onComplete?.call();
    });
  }

  /// Cancel any active board transition timers and unlock.
  void cancelBoardTransition() {
    _transitionTimer?.cancel();
    _transitionTimer = null;
    if (boardTransitioning) {
      boardTransitioning = false;
      undoRedoTransitionLock = false;
    }
  }
}
