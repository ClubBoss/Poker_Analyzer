import 'package:sentry_flutter/sentry_flutter.dart';
import '../live/live_runtime.dart';

/// Minimal telemetry wrapper around Sentry.
///
/// Planned events to wire:
/// - session_start
/// - session_end
/// - answer_correct
/// - answer_wrong
/// - answer_skip
/// - replay_errors
class Telemetry {
  static bool _enabled = false;

  static Future<void> init({String? dsn}) async {
    if (dsn == null || dsn.isEmpty) return;
    try {
      await SentryFlutter.init((o) => o.dsn = dsn);
      _enabled = true;
    } catch (_) {
      _enabled = false;
    }
  }

  static Future<void> logEvent(
    String name, [
    Map<String, dynamic>? props,
  ]) async {
    if (!_enabled) return;
    try {
      // Append current training mode to session lifecycle events only.
      if (name == 'session_start' || name == 'session_end') {
        final original = props ?? const <String, Object?>{};
        props = Map<String, Object?>.from(withMode(original));
      }
      await Sentry.captureMessage(
        name,
        withScope: (scope) {
          props?.forEach(scope.setExtra);
        },
      );
    } catch (_) {}
  }

  static Future<void> logError(Object error, StackTrace stack) async {
    if (!_enabled) return;
    try {
      await Sentry.captureException(error, stackTrace: stack);
    } catch (_) {}
  }
}

/// Returns current mode tag: 'live' or 'online'.
String liveModeTag() => LiveRuntime.isLive ? 'live' : 'online';

/// Returns a new map with 'mode' set from [liveModeTag()].
/// Does not mutate [base]. If 'mode' exists, it is overridden.
Map<String, Object?> withMode(Map<String, Object?> base) {
  final out = Map<String, Object?>.from(base);
  out['mode'] = liveModeTag();
  return out;
}
