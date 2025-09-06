import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:poker_analyzer/telemetry/telemetry.dart';
import 'package:poker_analyzer/live/live_telemetry.dart';
import 'package:poker_analyzer/live/live_validators.dart';
import 'package:poker_analyzer/infra/kpi_gate.dart';
import 'package:poker_analyzer/infra/kpi_fields_pure.dart' show kpiFields;
import 'package:poker_analyzer/infra/weakness_log.dart';
import 'package:poker_analyzer/infra/blitz_timer.dart';
import 'package:poker_analyzer/infra/rehab_hint.dart';
import 'package:poker_analyzer/infra/spaced_review.dart';

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
        final augmented = Map<String, Object?>.from(withMode(original));
        // Additive session_end metrics + KPI fields
        if (name == 'session_end') {
          // Try to read real stats from payload if provided; otherwise nulls
          final String? moduleId =
              (augmented['session_module_id'] as String?) ??
              (augmented['moduleId'] as String?) ??
              (augmented['packId'] as String?);
          final int? total = (augmented['session_total'] is int)
              ? augmented['session_total'] as int
              : (augmented['total'] is int ? augmented['total'] as int : null);
          final int? correct = (augmented['session_correct'] is int)
              ? augmented['session_correct'] as int
              : (augmented['correct'] is int
                    ? augmented['correct'] as int
                    : null);
          final int? avgMs = (augmented['session_avg_decision_ms'] is int)
              ? augmented['session_avg_decision_ms'] as int
              : (augmented['avgDecisionMs'] is int
                    ? augmented['avgDecisionMs'] as int
                    : null);
          // Optional weakness summary (additive only)
          if (kEnableWeaknessLog && weaknessLog.counts.isNotEmpty) {
            String? topFamily;
            int topCount = -1;
            weaknessLog.counts.forEach((k, v) {
              if (v > topCount) {
                topCount = v;
                topFamily = k;
              }
            });
            if (topFamily != null && topCount >= 0) {
              augmented['weakness_top_family'] = topFamily;
              augmented['weakness_top_count'] = topCount;
            }
          }
          augmented.addAll(
            kpiFields(
              moduleId: moduleId,
              total: total,
              correct: correct,
              avgMs: avgMs,
              enabled: kEnableKPI,
            ),
          );

          // Blitz timer instrumentation
          // - Always mirror the flag in blitz_enabled
          // - If enabled: ensure blitz_timeouts is present (default 0)
          // - If disabled: omit blitz_timeouts
          augmented['blitz_enabled'] = kEnableBlitz;
          if (kEnableBlitz) {
            final v = augmented['blitz_timeouts'];
            augmented['blitz_timeouts'] = v is int ? v : 0;
          } else {
            augmented.remove('blitz_timeouts');
          }

          // Rehab hint (additive): derive suggestions after KPI/weakness
          final bool kpiMet = augmented['kpi_met'] == true;
          final String? weaknessTop =
              augmented['weakness_top_family'] as String?;
          final List<String> hints = rehabHint(
            kpiMet: kpiMet,
            weaknessTop: weaknessTop,
          );
          if (hints.isNotEmpty) {
            augmented['rehab_hint'] = hints;
          }

          // Spaced review next timestamp (additive)
          if (kEnableSpaced &&
              (augmented['kpi_met'] is bool) &&
              total is int &&
              correct is int) {
            augmented['next_review_ts'] = nextReviewTs(
              kpiMet: kpiMet,
              correct: correct,
              total: total,
            ).toIso8601String();
          }
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
