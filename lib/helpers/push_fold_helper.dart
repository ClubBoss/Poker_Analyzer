const Map<String, int> kPushFoldThresholds = _buildPushFoldThresholds();

Map<String, int> _buildPushFoldThresholds() {
  const ranks = [
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'T',
    'J',
    'Q',
    'K',
    'A',
  ];
  final map = <String, int>{};
  int val(String r) => ranks.indexOf(r);
  void addPair(String r) {
    map['$r$r'] = 15;
  }

  void add(String a, String b, {bool suited = false, bool offsuit = false}) {
    final pair = [a, b]..sort((x, y) => val(y).compareTo(val(x)));
    if (offsuit) map['${pair[0]}${pair[1]}o'] = 15;
    if (suited) map['${pair[0]}${pair[1]}s'] = 15;
  }

  void addBoth(String a, String b) => add(a, b, suited: true, offsuit: true);

  void addSuited(String a, String b) => add(a, b, suited: true);

  for (final r in ranks) {
    addPair(r);
  }

  for (final r in ranks) {
    if (r == 'A') continue;
    addBoth('A', r);
  }

  for (final r in ['9', 'T', 'J', 'Q']) {
    addBoth('K', r);
  }

  for (final high in ['A', 'K', 'Q', 'J']) {
    for (final low in ['T', 'J', 'Q', 'K', 'A']) {
      if (high == low) continue;
      if (val(low) >= val('T')) addSuited(high, low);
    }
  }

  return map;
}
