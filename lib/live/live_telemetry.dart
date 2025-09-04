// ASCII-only; pure Dart (no Flutter deps)

import 'live_validators.dart';
import 'package:poker_analyzer/telemetry/telemetry.dart'; // withMode()

const String kLiveViolationEvent = 'live_procedure_violation';

/// Returns props ready for Telemetry.logEvent(kLiveViolationEvent, props).
Map<String, Object?> buildLiveViolationProps({
  required String moduleId,
  required LiveViolation violation,
}) {
  final base = <String, Object?>{'moduleId': moduleId, 'code': violation.code};
  return withMode(base); // adds 'mode': 'online'|'live'
}
