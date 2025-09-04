// ASCII-only; pure Dart (no Flutter deps)

import 'dart:async';
import 'live_mode.dart';

abstract class LiveModePersistor {
  Future<void> save(TrainingMode mode);
  Future<TrainingMode?> load();
}

/// Loads mode from persistor and applies it (default stays if null).
Future<void> initLiveModeFrom(LiveModePersistor p) async {
  final m = await p.load();
  if (m != null) LiveModeStore.set(m);
}

/// Subscribes to mode changes and persists them.
/// Returns a cancel function to remove the listener.
typedef Cancel = void Function();
Cancel persistLiveModeWith(LiveModePersistor p) {
  void listener(TrainingMode m) {
    // Fire-and-forget; errors bubble to zone.
    // ignore: discarded_futures
    p.save(m);
  }

  LiveModeStore.addListener(listener);
  // Persist current state immediately.
  // ignore: discarded_futures
  p.save(LiveModeStore.mode);
  return () => LiveModeStore.removeListener(listener);
}
