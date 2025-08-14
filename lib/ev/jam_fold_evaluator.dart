import 'dart:convert';
import 'dart:io';

import '../helpers/hand_utils.dart';
import '../models/action_entry.dart';
import '../utils/push_fold.dart';
import '../services/push_fold_ev_service.dart' show computePushEV;

class JamFoldResult {
  final double evJam;
  final double evFold;
  final String bestAction;
  final double delta;

  const JamFoldResult({
    required this.evJam,
    required this.evFold,
    required this.bestAction,
    required this.delta,
  });

  Map<String, dynamic> toJson() => {
        'evJam': evJam,
        'evFold': evFold,
        'bestAction': bestAction,
        'delta': delta,
      };
}

class JamFoldEvaluator {
  const JamFoldEvaluator();

  JamFoldResult? evaluateSpot(Map<String, dynamic> spot) {
    final hand = spot['hand'];
    if (hand is! Map<String, dynamic>) return null;

    final heroIndex = hand['heroIndex'] as int?;
    final playerCount = hand['playerCount'] as int?;
    final heroCards = hand['heroCards'] as String?;
    final stacks = hand['stacks'] as Map<String, dynamic>?;
    final anteBb = (hand['anteBb'] as num?)?.round() ?? 0;
    final actionsRaw = hand['actions'] as Map<String, dynamic>?;

    if (heroIndex == null ||
        playerCount == null ||
        heroCards == null ||
        stacks == null ||
        actionsRaw == null) {
      return null;
    }

    final actions = <int, List<ActionEntry>>{};
    for (final entry in actionsRaw.entries) {
      final street = int.tryParse(entry.key);
      if (street == null) continue;
      final list = (entry.value as List)
          .map(
            (e) => e is Map<String, dynamic> ? ActionEntry.fromJson(e) : null,
          )
          .whereType<ActionEntry>()
          .toList();
      actions[street] = list;
    }

    if (!isPushFoldSpot(actions, 0, heroIndex)) return null;

    final heroStack = (stacks['$heroIndex'] as num?)?.round();
    final handCodeStr = handCode(heroCards);
    if (heroStack == null || handCodeStr == null) return null;

    final evJam = computePushEV(
      heroBbStack: heroStack,
      bbCount: playerCount - 1,
      heroHand: handCodeStr,
      anteBb: anteBb,
    );
    const evFold = 0.0;
    final delta = evJam - evFold;
    final bestAction = delta >= 0 ? 'jam' : 'fold';

    return JamFoldResult(
      evJam: evJam,
      evFold: evFold,
      bestAction: bestAction,
      delta: delta,
    );
  }
}

String enrichJson(String content) {
  final data = jsonDecode(content);
  if (data is! Map<String, dynamic>) return content;
  final spots = data['spots'];
  if (spots is! List) return content;
  const evaluator = JamFoldEvaluator();
  for (final spot in spots) {
    if (spot is Map<String, dynamic>) {
      final res = evaluator.evaluateSpot(spot);
      if (res != null) {
        spot['jamFold'] = res.toJson();
      }
    }
  }
  return const JsonEncoder.withIndent('  ').convert(data);
}

class JamFoldMerger {
  const JamFoldMerger();

  Future<void> processFile(String inPath, String outPath) async {
    final inFile = File(inPath);
    final outFile = File(outPath);
    final original = await inFile.readAsString();
    final merged = enrichJson(original);
    final exists = await outFile.exists();
    final current = exists ? await outFile.readAsString() : '';
    if (current != merged) {
      await outFile.writeAsString(merged);
    }
  }
}
