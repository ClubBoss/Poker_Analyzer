class AutoRunMutex {
  bool _running = false;
  bool _queued = false;

  bool get isRunning => _running;

  Future<void> run(Future<void> Function() action, {bool force = false}) async {
    if (_running) {
      if (force) {
        _queued = true;
      }
      return;
    }
    _running = true;
    try {
      await action();
    } finally {
      _running = false;
      if (_queued) {
        _queued = false;
        await run(action);
      }
    }
  }
}
