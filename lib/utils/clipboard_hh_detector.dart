const _hhMarkers = [
  '*** hole cards ***', 'pokerstars', 'hand #', 'pokertracker',
  'карманные карты', 'раздача #', 'рука #',
];
bool containsPokerHistoryMarkers(String text) =>
    _hhMarkers.any(text.toLowerCase().contains);
