import 'dart:convert';

import 'package:poker_analyzer/ev/jam_fold_evaluator.dart';
import 'package:poker_analyzer/helpers/hand_utils.dart';
import 'package:poker_analyzer/services/push_fold_ev_service.dart';
import 'package:test/test.dart';

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
