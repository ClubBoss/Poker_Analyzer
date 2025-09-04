// ASCII-only; pure Dart (no Flutter deps)

import 'live_mode.dart';
import 'live_mode_persistence.dart';

// Append-only key for persisted mode value.
const String kLiveModeKey = 'live.mode';

/// Generic callback-based persistor that reads/writes the live mode
/// using provided asynchronous functions.
class FunctionLiveModePersistor implements LiveModePersistor {
  final Future<String?> Function(String key) read;
  final Future<void> Function(String key, String value) write;

  FunctionLiveModePersistor({required this.read, required this.write});

  @override
  Future<TrainingMode?> load() async {
    final v = await read(kLiveModeKey);
    if (v == 'live') return TrainingMode.live;
    if (v == 'online') return TrainingMode.online;
    return null;
  }

  @override
  Future<void> save(TrainingMode mode) =>
      write(kLiveModeKey, mode == TrainingMode.live ? 'live' : 'online');
}
