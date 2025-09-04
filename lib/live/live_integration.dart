// ASCII-only; pure Dart (no Flutter deps)

import 'live_runtime.dart';
import 'live_messages.dart';
import 'live_validators.dart';
import 'live_defaults.dart';

/// Returns the first LiveViolation for the given module and mode, or null.
LiveViolation? evaluateLiveProceduresForModule({
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
  // Online mode has no live procedure violations.
  if (mode != TrainingMode.live) return null;
  final LiveContext ctx = defaultLiveContextFor(mode: mode, moduleId: moduleId);
  return LiveRuntime.firstViolation(
    ctx: ctx,
    announced: announced,
    chipMotions: chipMotions,
    singleMotion: singleMotion,
    bettorWasAggressor: bettorWasAggressor,
    bettorShowedFirst: bettorShowedFirst,
    headsUp: headsUp,
    firstActiveLeftOfBtnShowed: firstActiveLeftOfBtnShowed,
  );
}

/// Convenience: human-readable warning or empty string.
String liveWarningIfAny({
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
  return liveMessageFor(v);
}
