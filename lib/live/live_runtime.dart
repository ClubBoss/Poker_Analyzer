// ASCII-only; pure Dart (no Flutter deps)

import 'live_mode.dart';
import 'live_defaults.dart';
import 'live_badges.dart';
import 'live_context_format.dart';
import 'live_validators.dart';
import 'live_messages.dart';
import 'live_actions.dart';

/// Single entrypoint for Live overlay logic.
class LiveRuntime {
  LiveRuntime._();

  static TrainingMode get mode => LiveModeStore.mode;
  static bool get isLive => LiveModeStore.isLive;
  static void setMode(TrainingMode next) => LiveModeStore.set(next);
  static void toggle() => LiveModeStore.toggle();

  /// Badges for module card.
  static List<String> badgesForModule(String moduleId) =>
      liveBadgesForModule(moduleId: moduleId, mode: mode);

  /// Default context for a module given current mode.
  static LiveContext contextFor(String moduleId) =>
      defaultLiveContextFor(mode: mode, moduleId: moduleId);

  /// Human-readable subtitle from the default context for a module in current mode.
  static String subtitleFor(String moduleId) =>
      liveContextSubtitle(contextFor(moduleId));

  /// Primary action label for module in current mode, or null.
  static String? primaryActionFor(String moduleId) =>
      livePrimaryAction(moduleId, mode);

  /// Run all live procedure checks and return the first violation, if any.
  static LiveViolation? firstViolation({
    required LiveContext ctx,
    required bool announced,
    required int chipMotions,
    required bool singleMotion,
    required bool bettorWasAggressor,
    required bool bettorShowedFirst,
    required bool headsUp,
    required bool firstActiveLeftOfBtnShowed,
  }) {
    return checkStringBet(
          ctx: ctx,
          announced: announced,
          chipMotions: chipMotions,
        ) ??
        checkSingleMotionRaise(ctx: ctx, singleMotion: singleMotion) ??
        checkBettorShowsFirst(
          ctx: ctx,
          bettorWasAggressor: bettorWasAggressor,
          bettorShowedFirst: bettorShowedFirst,
        ) ??
        checkFirstActiveLeftOfBtnShows(
          ctx: ctx,
          headsUp: headsUp,
          firstActiveLeftOfBtnShowed: firstActiveLeftOfBtnShowed,
        );
  }

  /// Human-readable message for a violation or empty string.
  static String messageFor(LiveViolation? v) => liveMessageFor(v);
}
