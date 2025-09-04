import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:poker_analyzer/telemetry/telemetry.dart';
import 'package:poker_analyzer/live/live_telemetry.dart';
import 'package:poker_analyzer/live/live_validators.dart';

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
      // Append current training mode to selected events.
      if (name == 'session_start' ||
          name == 'session_end' ||
          name == 'session_abort' ||
          name == 'export_l3_errors_file' ||
          name == 'export_l3_errors_failed' ||
          name == 'export_l3_errors_clipboard') {
        final original = props ?? const <String, Object?>{};
        props = Map<String, Object?>.from(withMode(original));
      }
      await Sentry.captureMessage(
        name,
        withScope: (scope) {
          // ignore: deprecated_member_use
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

  // Live: emit a standardized violation event.
  static Future<void> logLiveViolation({
    required String moduleId,
    required LiveViolation violation,
  }) async {
    final props = buildLiveViolationProps(
      moduleId: moduleId,
      violation: violation,
    );
    await logEvent(kLiveViolationEvent, Map<String, dynamic>.from(props));
  }
}
