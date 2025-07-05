const _hhMarkers = [
  '*** hole cards ***',
  'pokerstars',
  'hand #',
  'pokertracker',
  'карманные карты',
  'раздача #',
  'рука #',
];

bool containsPokerHistoryMarkers(String text) {
  final lower = text.toLowerCase();
  return _hhMarkers.any(lower.contains);
}
