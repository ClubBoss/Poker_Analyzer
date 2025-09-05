import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:poker_analyzer/telemetry/telemetry.dart';
import 'package:poker_analyzer/live/live_telemetry.dart';
import 'package:poker_analyzer/live/live_validators.dart';
import 'package:poker_analyzer/infra/kpi_gate.dart';
import 'package:poker_analyzer/infra/kpi_fields_pure.dart' show kpiFields;

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
        var augmented = Map<String, Object?>.from(withMode(original));
        // Additive session_end metrics + KPI fields
        if (name == 'session_end') {
          // Try to read real stats from payload if provided; otherwise nulls
          final String? moduleId = (augmented['moduleId'] as String?) ??
              (augmented['packId'] as String?);
          final int? total = augmented['total'] is int ? augmented['total'] as int : null;
          final int? correct = augmented['correct'] is int ? augmented['correct'] as int : null;
          final int? avgMs = augmented['avgDecisionMs'] is int
              ? augmented['avgDecisionMs'] as int
              : null;
          augmented.addAll(kpiFields(
            moduleId: moduleId,
            total: total,
            correct: correct,
            avgMs: avgMs,
            enabled: kEnableKPI,
          ));
        }
        props = augmented;
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
