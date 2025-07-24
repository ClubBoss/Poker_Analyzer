
const _ranks = '23456789TJQKA';

String? handTypeLabelError(String label) {
  final l = label.trim().toUpperCase();
  if (l.isEmpty) return 'Empty label';
  if ({
        'PAIRS',
        'SMALL PAIRS',
        'MID PAIRS',
        'BIG PAIRS',
        'LOW PAIRS',
        'HIGH PAIRS',
        'SUITED CONNECTORS',
        'OFFSUIT CONNECTORS',
        'CONNECTORS',
        'SUITED AX',
        'OFFSUIT AX'
      }.contains(l)) {
    return null;
  }
  if (RegExp(r'^[2-9TJQKA]X[so]?$').hasMatch(l)) return null;
  if (RegExp(r'^[2-9TJQKA]{2}(?:[so](?:\+)?|\+)?$').hasMatch(l)) return null;
  return 'Invalid hand type (e.g. JXs, 76s+, suited connectors)';
}


bool matchHandTypeLabel(String label, String handCode) {
  final l = label.trim().toUpperCase();
  final code = handCode.toUpperCase();
  final hi = code[0];
  final lo = code.length > 1 ? code[1] : '';
  final suited = code.endsWith('S');
  if (l == 'PAIRS') return code.length == 2;
  if (l == 'SMALL PAIRS' || l == 'LOW PAIRS') {
    return code.length == 2 && _ranks.indexOf(hi) <= _ranks.indexOf('6');
  }
  if (l == 'MID PAIRS') {
    return code.length == 2 &&
        _ranks.indexOf(hi) > _ranks.indexOf('6') &&
        _ranks.indexOf(hi) <= _ranks.indexOf('T');
  }
  if (l == 'BIG PAIRS' || l == 'HIGH PAIRS') {
    return code.length == 2 && _ranks.indexOf(hi) > _ranks.indexOf('T');
  }
  if (l == 'SUITED CONNECTORS') {
    return suited && _ranks.indexOf(hi) - _ranks.indexOf(lo) == 1;
  }
  if (l == 'OFFSUIT CONNECTORS') {
    return !suited && _ranks.indexOf(hi) - _ranks.indexOf(lo) == 1;
  }
  if (l == 'CONNECTORS') {
    return _ranks.indexOf(hi) - _ranks.indexOf(lo) == 1;
  }
  if (l == 'SUITED AX') {
    return code.startsWith('A') && suited && code.length == 3 && hi != lo;
  }
  if (l == 'OFFSUIT AX') {
    return code.startsWith('A') && !suited && code.length == 3 && hi != lo;
  }
  final m1 = RegExp(r'^([2-9TJQKA])X([so])?$').firstMatch(l);
  if (m1 != null) {
    final r = m1.group(1)!;
    final s = m1.group(2);
    if (code.length != 3 || code[0] != r || hi == lo) return false;
    if (s == 'S' && !suited) return false;
    if (s == 'O' && suited) return false;
    return true;
  }
  final m2 = RegExp(r'^([2-9TJQKA])([2-9TJQKA])([so](?:\+)?|\+)?$').firstMatch(l);
  if (m2 != null) {
    final h = m2.group(1)!;
    final lw = m2.group(2)!;
    final s = m2.group(3);
    final plus = s?.contains('+') == true;
    final hiIdx = _ranks.indexOf(hi);
    final loIdx = _ranks.indexOf(lo);
    final hIdx = _ranks.indexOf(h);
    final lwIdx = _ranks.indexOf(lw);
    final diff = hiIdx - loIdx;
    final baseDiff = hIdx - lwIdx;
    if (s == 'S' && !suited) return false;
    if (s == 'O' && suited) return false;
    if (plus) {
      return diff == baseDiff && hiIdx >= hIdx && loIdx >= lwIdx;
    }
    return code.startsWith('$h$lw') && diff == baseDiff && (s == null || (s == 'S' ? suited : !suited));
  }
  return false;
}
