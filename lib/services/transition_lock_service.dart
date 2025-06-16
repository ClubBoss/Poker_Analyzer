import "dart:async";
import "package:flutter/widgets.dart";

/// Coordinates board transition locking across services and widgets.
class TransitionLockService {
  bool boardTransitioning = false;
  bool undoRedoTransitionLock = false;
  bool _genericLock = false;

  Timer? _transitionTimer;
  Timer? _genericTimer;

  bool get isLocked => boardTransitioning || _genericLock;

  /// Execute [fn] inside `setState` if the transition lock allows it.
  void safeSetState(
    State state,
    VoidCallback fn, {
    bool ignoreTransitionLock = false,
  }) {
    if (!state.mounted) return;
    if (isLocked && !ignoreTransitionLock) return;
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

  /// Manually lock all transitions for [duration].
  void lock([Duration? duration]) {
    _genericTimer?.cancel();
    _genericLock = true;
    if (duration != null) {
      _genericTimer = Timer(duration, unlock);
    }
  }

  /// Unlock any manual transition locks.
  void unlock() {
    _genericTimer?.cancel();
    _genericTimer = null;
    _genericLock = false;
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
