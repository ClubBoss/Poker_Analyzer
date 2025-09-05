import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:poker_analyzer/telemetry/telemetry.dart';
import 'package:poker_analyzer/live/live_telemetry.dart';
import 'package:poker_analyzer/live/live_validators.dart';
import 'package:poker_analyzer/infra/kpi_gate.dart';

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
        // Append KPI fields for session_end event (additive only; harmless when disabled)
        if (name == 'session_end') {
          final moduleId = (augmented['moduleId'] ?? '').toString();
          final correct = (augmented['correct'] is int) ? augmented['correct'] as int : 0;
          final total = (augmented['total'] is int) ? augmented['total'] as int : 0;
          final avgMs = (augmented['avgDecisionMs'] is int)
              ? augmented['avgDecisionMs'] as int
              : 0;
          final target = kModuleKPI[moduleId] ?? const KPITarget(80, 25000);
          augmented['kpi_enabled'] = kEnableKPI;
          augmented['kpi_target_accuracy'] = target.minAccuracyPct;
          augmented['kpi_target_time_ms'] = target.maxAvgMs;
          augmented['kpi_met'] = meetsKPI(
            moduleId: moduleId,
            correct: correct,
            total: total,
            avgDecisionMs: avgMs,
          );
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
