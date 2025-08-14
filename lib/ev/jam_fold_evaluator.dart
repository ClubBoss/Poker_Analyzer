import 'dart:convert';
import 'dart:io';

import '../models/action_entry.dart';
import '../services/push_fold_ev_service.dart';
import '../utils/push_fold.dart';

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
    final handCodeStr = _handCode(heroCards);
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

String? _handCode(String twoCardString) {
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
