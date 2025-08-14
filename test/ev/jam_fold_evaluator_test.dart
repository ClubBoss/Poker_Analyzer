import 'dart:convert';

import 'package:poker_analyzer/ev/jam_fold_evaluator.dart';
import 'package:test/test.dart';

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

final List<String> _handRanking = (() {
  const ranks = [
    'A',
    'K',
    'Q',
    'J',
    'T',
    '9',
    '8',
    '7',
    '6',
    '5',
    '4',
    '3',
    '2',
  ];
  final hands = <String>[];
  for (var i = 0; i < ranks.length; i++) {
    for (var j = 0; j < ranks.length; j++) {
      if (i == j) {
        hands.add('${ranks[i]}${ranks[j]}');
      } else if (i < j) {
        hands.add('${ranks[i]}${ranks[j]}s');
      } else {
        hands.add('${ranks[j]}${ranks[i]}o');
      }
    }
  }
  int score(String h) {
    const map = {
      '2': 2,
      '3': 3,
      '4': 4,
      '5': 5,
      '6': 6,
      '7': 7,
      '8': 8,
      '9': 9,
      'T': 10,
      'J': 11,
      'Q': 12,
      'K': 13,
      'A': 14,
    };
    final r1 = map[h[0]]!;
    final r2 = map[h[1]]!;
    final suited = h.length == 3 && h[2] == 's';
    if (r1 == r2) return r1 * 20;
    final high = r1 > r2 ? r1 : r2;
    final low = r1 > r2 ? r2 : r1;
    var s = high * 2 + low / 10;
    if (suited) s += 1;
    return (s * 100).round();
  }

  hands.sort((a, b) => score(b).compareTo(score(a)));
  return List<String>.unmodifiable(hands);
})();

final Map<String, double> _equity = {
  for (int i = 0; i < _handRanking.length; i++)
    _handRanking[i]: 0.85 - i * (0.55 / (_handRanking.length - 1)),
};

final Map<String, double> _evCache = {};

double computePushEV({
  required int heroBbStack,
  required int bbCount,
  required String heroHand,
  required int anteBb,
}) {
  final key = '$heroBbStack|$bbCount|$heroHand|$anteBb';
  return _evCache.putIfAbsent(key, () {
    final eq = _equity[heroHand] ?? 0.5;
    final pot = (bbCount + 1) * anteBb + 1.5;
    final bet = heroBbStack.toDouble();
    return eq * (pot + bet) - (1 - eq) * bet;
  });
}

Map<String, dynamic> spotForHand(String cards) {
  return {
    'hand': {
      'heroCards': cards,
      'heroIndex': 0,
      'playerCount': 2,
      'stacks': {'0': 10, '1': 10},
      'actions': {
        '0': [
          {'street': 0, 'playerIndex': 0, 'action': 'push', 'amount': 10},
          {'street': 0, 'playerIndex': 1, 'action': 'fold'},
        ],
      },
      'anteBb': 0,
    },
  };
}

void main() {
  const evaluator = JamFoldEvaluator();

  test('deterministic outputs for canonical hands', () {
    final strong = evaluator.evaluateSpot(spotForHand('As Ks'))!;
    final strongEv = computePushEV(
      heroBbStack: 10,
      bbCount: 1,
      heroHand: handCode('As Ks')!,
      anteBb: 0,
    );
    expect(strong.evJam, strongEv);
    expect(strong.bestAction, 'jam');

    final weak = evaluator.evaluateSpot(spotForHand('7c 2d'))!;
    final weakEv = computePushEV(
      heroBbStack: 10,
      bbCount: 1,
      heroHand: handCode('7c 2d')!,
      anteBb: 0,
    );
    expect(weak.evJam, weakEv);
    expect(weak.bestAction, 'fold');

    final mid = evaluator.evaluateSpot(spotForHand('Qh Jd'))!;
    final midEv = computePushEV(
      heroBbStack: 10,
      bbCount: 1,
      heroHand: handCode('Qh Jd')!,
      anteBb: 0,
    );
    expect(mid.evJam, midEv);
  });

  test('JSON backward compatibility and idempotence', () async {
    final originalMap = {
      'spots': [spotForHand('As Ks')],
    };
    final originalJson = const JsonEncoder.withIndent(
      '  ',
    ).convert(originalMap);

    final mergedJson = enrichJson(originalJson);
    final mergedMap = jsonDecode(mergedJson) as Map<String, dynamic>;

    // jamFold should be added
    final spot = mergedMap['spots'][0] as Map<String, dynamic>;
    expect(spot['jamFold'], isNotNull);

    // Removing jamFold yields original map
    spot.remove('jamFold');
    expect(mergedMap, originalMap);

    // idempotent formatting
    final mergedTwice = enrichJson(mergedJson);
    expect(mergedTwice, mergedJson);
  });
}
