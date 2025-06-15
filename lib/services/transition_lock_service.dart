import "package:flutter/widgets.dart";
class TransitionLockService {
  bool boardTransitioning = false;
  bool undoRedoTransitionLock = false;

  void safeSetState(
    State state,
    VoidCallback fn, {
    bool ignoreTransitionLock = false,
  }) {
    if (!state.mounted) return;
    if (boardTransitioning && !ignoreTransitionLock) return;
    state.setState(fn);
  }
}
