// ASCII-only; pure Dart (no Flutter deps)

import 'live_context.dart';

class LiveViolation {
  final String code;
  final String message;

  const LiveViolation(this.code, this.message);

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LiveViolation &&
        other.code == code &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(code, message);

  @override
  String toString() =>
      'LiveViolation(code: ' + code + ', message: ' + message + ')';
}

typedef LiveCheck = LiveViolation?;

// Returns null on pass, LiveViolation on fail
LiveCheck checkStringBet({
  required LiveContext ctx,
  required bool announced,
  required int chipMotions,
}) {
  if (ctx.announceRequired && chipMotions > 1 && !announced) {
    return const LiveViolation(
      'string_bet_call_only',
      'String bets without announce are call-only when announce is required.',
    );
  }
  return null;
}

LiveCheck checkSingleMotionRaise({
  required LiveContext ctx,
  required bool singleMotion,
}) {
  if (ctx.announceRequired && !singleMotion) {
    return const LiveViolation(
      'single_motion_raise_required',
      'Raises must be a single motion when announce is required.',
    );
  }
  return null;
}

LiveCheck checkBettorShowsFirst({
  required LiveContext ctx,
  required bool bettorWasAggressor,
  required bool bettorShowedFirst,
}) {
  if (bettorWasAggressor && !bettorShowedFirst) {
    return const LiveViolation(
      'bettor_shows_first_required',
      'Bettor or last aggressor must show first.',
    );
  }
  return null;
}

LiveCheck checkFirstActiveLeftOfBtnShows({
  required LiveContext ctx,
  required bool headsUp,
  required bool firstActiveLeftOfBtnShowed,
}) {
  if (!headsUp && !firstActiveLeftOfBtnShowed) {
    return const LiveViolation(
      'first_active_left_of_btn_shows_required',
      'First active player left of the button must show.',
    );
  }
  return null;
}
