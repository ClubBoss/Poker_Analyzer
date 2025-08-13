/// Provides simple similarity lookup for flop boards.
class BoardSimilarityEngine {
  const BoardSimilarityEngine();

  static const Map<String, List<List<String>>> _clusters = {
    'low_connected': [
      ['4h', '5d', '6s'],
      ['5c', '6d', '7h'],
      ['6s', '7c', '8d'],
      ['7d', '8s', '9c'],
      ['8c', '9d', 'Ts'],
    ],
    'dry_high': [
      ['Ah', 'Kd', '7c'],
      ['Kh', 'Qd', '3s'],
      ['Ad', 'Jc', '6h'],
      ['Ks', 'Td', '4c'],
      ['Qh', '8d', '5s'],
    ],
    'monotone': [
      ['2h', '6h', '9h'],
      ['3d', '7d', 'Jd'],
      ['4c', '8c', 'Qc'],
      ['5s', '9s', 'Ks'],
      ['Ah', 'Jh', '4h'],
    ],
    'paired': [
      ['Ah', 'Ad', '7c'],
      ['Kd', 'Ks', '4h'],
      ['Qh', 'Qd', '5s'],
      ['Jh', 'Jc', '8d'],
      ['Ts', 'Td', '3c'],
    ],
  };

  /// Returns a single flop similar in texture to [flop].
  /// If no similar flop is found, returns an empty list.
  List<String> getSimilarFlop(List<String> flop) {
    final options = _clusters[_classify(flop)] ?? [];
    if (options.isEmpty) return <String>[];
    return options.first;
  }

  String _classify(List<String> flop) {
    if (flop.length < 3) return 'dry_high';
    final suits = flop.map((c) => c.substring(1)).toSet();
    if (suits.length == 1) return 'monotone';
    final ranks = flop.map((c) => c[0].toUpperCase()).toList();
    final counts = <String, int>{};
    for (final r in ranks) {
      counts[r] = (counts[r] ?? 0) + 1;
    }
    if (counts.values.any((c) => c >= 2)) return 'paired';
    final values = ranks.map(_rankValue).toList()..sort();
    if (values.last <= _rankValue('T') && values.last - values.first <= 4) {
      return 'low_connected';
    }
    return 'dry_high';
  }

  int _rankValue(String r) {
    const order = '23456789TJQKA';
    return order.indexOf(r) + 2;
  }
}
