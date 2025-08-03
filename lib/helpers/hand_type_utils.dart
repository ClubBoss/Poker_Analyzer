const _ranks = '23456789TJQKA';

bool _isLowPairs(String code) {
  final hi = code[0];
  return code.length == 2 && _ranks.indexOf(hi) <= _ranks.indexOf('6');
}

bool _isHighPairs(String code) {
  final hi = code[0];
  return code.length == 2 && _ranks.indexOf(hi) > _ranks.indexOf('T');
}

final Map<String, bool Function(String)> _labelMatchers = {
  'PAIRS': (code) => code.length == 2,
  'SMALL PAIRS': _isLowPairs,
  'MID PAIRS': (code) {
    final hi = code[0];
    return code.length == 2 &&
        _ranks.indexOf(hi) > _ranks.indexOf('6') &&
        _ranks.indexOf(hi) <= _ranks.indexOf('T');
  },
  'BIG PAIRS': _isHighPairs,
  'SUITED CONNECTORS': (code) {
    final hi = code[0];
    final lo = code.length > 1 ? code[1] : '';
    return code.endsWith('S') && _ranks.indexOf(hi) - _ranks.indexOf(lo) == 1;
  },
  'OFFSUIT CONNECTORS': (code) {
    final hi = code[0];
    final lo = code.length > 1 ? code[1] : '';
    return !code.endsWith('S') && _ranks.indexOf(hi) - _ranks.indexOf(lo) == 1;
  },
  'CONNECTORS': (code) {
    final hi = code[0];
    final lo = code.length > 1 ? code[1] : '';
    return _ranks.indexOf(hi) - _ranks.indexOf(lo) == 1;
  },
  'SUITED AX': (code) {
    final hi = code[0];
    final lo = code.length > 1 ? code[1] : '';
    return code.startsWith('A') &&
        code.endsWith('S') &&
        code.length == 3 &&
        hi != lo;
  },
  'OFFSUIT AX': (code) {
    final hi = code[0];
    final lo = code.length > 1 ? code[1] : '';
    return code.startsWith('A') &&
        !code.endsWith('S') &&
        code.length == 3 &&
        hi != lo;
  },
}..addAll({'LOW PAIRS': _isLowPairs, 'HIGH PAIRS': _isHighPairs});

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
    'OFFSUIT AX',
  }.contains(l)) {
    return null;
  }
  if (RegExp(r'^[2-9TJQKA]X[so]?$').hasMatch(l)) return null;
  if (RegExp(r'^[2-9TJQKA]{2}(?:[so](?:\\+)?|\\+)?$').hasMatch(l)) return null;
  return 'Invalid hand type (e.g. JXs, 76s+, suited connectors)';
}

bool matchHandTypeLabel(String label, String handCode) {
  final l = label.trim().toUpperCase();
  final code = handCode.toUpperCase();
  final matcher = _labelMatchers[l];
  if (matcher != null) return matcher(code);

  final m1 = RegExp(r'^([2-9TJQKA])X([so])?$').firstMatch(l);
  if (m1 != null) {
    final r = m1.group(1)!;
    final s = m1.group(2);
    bool fn(String c) {
      final hi = c[0];
      final lo = c.length > 1 ? c[1] : '';
      final suited = c.endsWith('S');
      if (c.length != 3 || hi != r || hi == lo) return false;
      if (s == 'S' && !suited) return false;
      if (s == 'O' && suited) return false;
      return true;
    }

    _labelMatchers[l] = fn;
    return fn(code);
  }

  final m2 = RegExp(
    r'^([2-9TJQKA])([2-9TJQKA])([so](?:\\+)?|\\+)?$',
  ).firstMatch(l);
  if (m2 != null) {
    final h = m2.group(1)!;
    final lw = m2.group(2)!;
    final s = m2.group(3);
    final plus = s?.contains('+') == true;
    final hIdx = _ranks.indexOf(h);
    final lwIdx = _ranks.indexOf(lw);
    final baseDiff = hIdx - lwIdx;
    bool fn(String c) {
      final hi = c[0];
      final lo = c.length > 1 ? c[1] : '';
      final suited = c.endsWith('S');
      final hiIdx = _ranks.indexOf(hi);
      final loIdx = _ranks.indexOf(lo);
      final diff = hiIdx - loIdx;
      if (s == 'S' && !suited) return false;
      if (s == 'O' && suited) return false;
      if (plus) {
        return diff == baseDiff && hiIdx >= hIdx && loIdx >= lwIdx;
      }
      return c.startsWith('$h$lw') &&
          diff == baseDiff &&
          (s == null || (s == 'S' ? suited : !suited));
    }

    _labelMatchers[l] = fn;
    return fn(code);
  }

  return false;
}
