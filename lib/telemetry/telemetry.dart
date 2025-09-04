// ASCII-only; pure Dart (no Flutter deps)

import '../live/live_runtime.dart';

String liveModeTag() => LiveRuntime.isLive ? 'live' : 'online';

Map<String, Object?> withMode(Map<String, Object?> base) {
  final out = Map<String, Object?>.from(base);
  out['mode'] = liveModeTag();
  return out;
}
