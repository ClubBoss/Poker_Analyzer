import '../models/saved_hand.dart';
import '../models/action_entry.dart';

int _rankVal(String r) {
  const order = {
    '2': 0,
    '3': 1,
    '4': 2,
    '5': 3,
    '6': 4,
    '7': 5,
    '8': 6,
    '9': 7,
    'T': 8,
    'J': 9,
    'Q': 10,
    'K': 11,
    'A': 12,
  };
  return order[r] ?? -1;
}

String? handCode(String twoCardString) {
  final parts = twoCardString.split(RegExp(r'\s+'));
  if (parts.length < 2) return null;
  final r1 = parts[0][0].toUpperCase();
  final s1 = parts[0].substring(1);
  final r2 = parts[1][0].toUpperCase();
  final s2 = parts[1].substring(1);
  if (r1 == r2) return '$r1$r2';
  final firstHigh = _rankVal(r1) >= _rankVal(r2);
  final high = firstHigh ? r1 : r2;
  final low = firstHigh ? r2 : r1;
  final suited = s1 == s2;
  return '$high$low${suited ? 's' : 'o'}';
}

ActionEntry? heroAction(SavedHand hand) {
  for (final a in hand.actions) {
    if (a.playerIndex == hand.heroIndex) return a;
  }
  return null;
}
