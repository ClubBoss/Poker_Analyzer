int _rankVal(String r) {
  const order = [
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
    'A'
  ];
  return order.indexOf(r);
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
