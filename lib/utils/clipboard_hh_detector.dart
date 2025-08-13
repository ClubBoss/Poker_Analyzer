const Set<String> _hhMarkers = {
  '*** hole cards ***',
  'pokerstars',
  'hand #',
  'pokertracker',
  'карманные карты',
  'раздача #',
  'рука #',
};

bool containsPokerHistoryMarkers(String text) {
  final lowerText = text.toLowerCase();
  return _hhMarkers.any(lowerText.contains);
}
