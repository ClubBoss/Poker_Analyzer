// ASCII-only; pure Dart adapter with no side effects.

import 'live.dart'; // barrel for LiveRuntime, TrainingMode, messageFor, etc.
import 'live_telemetry.dart'; // kLiveViolationEvent, buildLiveViolationProps

class LiveEventOutcome {
  final String warning; // "" if none
  final Map<String, Object?>? telemetryProps; // null if none
  const LiveEventOutcome({required this.warning, this.telemetryProps});
  bool get hasViolation => telemetryProps != null;
}

/// Computes warning and telemetry props for a single action.
/// Does NOT emit telemetry. Caller decides when/where to log.
LiveEventOutcome processLiveAction({
  required String moduleId,
  required TrainingMode mode,
  required bool announced,
  required int chipMotions,
  required bool singleMotion,
  required bool bettorWasAggressor,
  required bool bettorShowedFirst,
  required bool headsUp,
  required bool firstActiveLeftOfBtnShowed,
}) {
  final v = evaluateLiveProceduresForModule(
    moduleId: moduleId,
    mode: mode,
    announced: announced,
    chipMotions: chipMotions,
    singleMotion: singleMotion,
    bettorWasAggressor: bettorWasAggressor,
    bettorShowedFirst: bettorShowedFirst,
    headsUp: headsUp,
    firstActiveLeftOfBtnShowed: firstActiveLeftOfBtnShowed,
  );
  if (v == null) return const LiveEventOutcome(warning: "");
  final msg = LiveRuntime.messageFor(v);
  final props = buildLiveViolationProps(moduleId: moduleId, violation: v);
  return LiveEventOutcome(warning: msg, telemetryProps: props);
}
