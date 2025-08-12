// Utility helpers for push/fold spot handling.

import '../models/action_entry.dart';

const kPushSynonyms = {'push', 'shove', 'jam', 'allin', 'all-in', 'all_in'};

const kPushKey = 'push';

String normalizeAction(String a) {
  final v = a.toLowerCase();
  return kPushSynonyms.contains(v) ? kPushKey : v;
}

List<ActionEntry> actionsForStreet(
  Map<int, List<ActionEntry>> actions,
  int street,
) {
  return actions[street] ?? const <ActionEntry>[];
}

bool isPushFoldSpot(
  Map<int, List<ActionEntry>> actions,
  int street,
  int heroIdx,
) {
  final acts = actionsForStreet(actions, street);
  final hasPush = acts.any(
    (a) => a.playerIndex == heroIdx && normalizeAction(a.action) == kPushKey,
  );
  final hasFold = acts.any(
    (a) => a.playerIndex != heroIdx && normalizeAction(a.action) == 'fold',
  );
  return hasPush && hasFold;
}
