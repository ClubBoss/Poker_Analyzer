// ASCII-only; pure Dart (no Flutter deps)

import 'dart:core';

import 'live_validators.dart';

// Maps validator codes to concise UI messages.
const Map<String, String> kLiveViolationMessages = {
  'string_bet_call_only':
      'Multiple chip motions without a spoken bet = string bet. Call only.',
  'single_motion_raise_required':
      'Raises must be a single motion or clearly announced.',
  'bettor_shows_first_required': 'Aggressor shows first at showdown.',
  'first_active_left_of_btn_shows_required':
      'In multiway pots the first active player left of the button shows first.',
};

String liveMessageForCode(String code) {
  return kLiveViolationMessages[code] ?? 'Live procedure violation.';
}

String liveMessageFor(LiveViolation? v) {
  if (v == null) return '';
  return liveMessageForCode(v.code);
}
