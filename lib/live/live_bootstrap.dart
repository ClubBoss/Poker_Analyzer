// ASCII-only; pure Dart (no Flutter deps)

import 'live_mode_persistence.dart';
import 'live_mode_persistors.dart';

/// Wire Live mode to your existing key-value storage via callbacks.
Future<void> initLiveModeWith({
  required Future<String?> Function(String key) read,
  required Future<void> Function(String key, String value) write,
}) async {
  final p = FunctionLiveModePersistor(read: read, write: write);
  await initLiveModeFrom(p);
  // Keep it persisted on changes; caller can hold the cancel to dispose on app shutdown.
  persistLiveModeWith(p);
}
