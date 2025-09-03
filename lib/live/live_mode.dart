// ASCII-only; pure Dart (no Flutter deps)

/// TrainingMode governs Online vs Live overlay.
enum TrainingMode { online, live }

/// LiveModeStore is a minimal observable without Flutter deps.
/// Default = online. Listeners get called on every mode change.
class LiveModeStore {
  LiveModeStore._();

  static TrainingMode _mode = TrainingMode.online;
  static TrainingMode get mode => _mode;
  static bool get isLive => _mode == TrainingMode.live;

  static void set(TrainingMode next) {
    if (_mode == next) return;
    _mode = next;
    for (final l in List<void Function(TrainingMode)>.from(_listeners)) {
      l(_mode);
    }
  }

  static void toggle() => set(isLive ? TrainingMode.online : TrainingMode.live);

  static final List<void Function(TrainingMode)> _listeners =
      <void Function(TrainingMode)>[];
  static void addListener(void Function(TrainingMode) listener) {
    if (!_listeners.contains(listener)) _listeners.add(listener);
  }

  static void removeListener(void Function(TrainingMode) listener) {
    _listeners.remove(listener);
  }
}
