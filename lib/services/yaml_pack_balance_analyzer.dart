import '../models/pack_balance_issue.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';

class YamlPackBalanceAnalyzer {
  const YamlPackBalanceAnalyzer();

  List<PackBalanceIssue> analyze(TrainingPackTemplateV2 pack) {
    final spots = pack.spots;
    final issues = <PackBalanceIssue>[];
    if (spots.isEmpty) return issues;
    final pos = <String, int>{};
    final acts = <String, int>{};
    final streets = <int, int>{};
    final stacks = <int, int>{};
    for (final s in spots) {
      final p = s.hand.position.name;
      pos[p] = (pos[p] ?? 0) + 1;
      final a = _heroAction(s);
      if (a != null) acts[a] = (acts[a] ?? 0) + 1;
      final st = s.street;
      streets[st] = (streets[st] ?? 0) + 1;
      final stack = s.hand.stacks['${s.hand.heroIndex}']?.round() ?? 0;
      stacks[stack] = (stacks[stack] ?? 0) + 1;
    }
    final total = spots.length;
    void checkBias(String type, Map<dynamic, int> map, int severity) {
      if (map.length <= 1) return;
      final entry = map.entries.reduce((a, b) => b.value > a.value ? b : a);
      final pct = entry.value / total;
      if (pct > 0.7) {
        issues.add(PackBalanceIssue(
          type: type,
          description: '${entry.key} ${(pct * 100).round()}%',
          severity: severity,
        ));
      }
    }

    checkBias('position_bias', pos, 2);
    checkBias('action_repetition', acts, 1);
    checkBias('street_bias', streets, 1);
    checkBias('stack_bias', stacks, 1);

    final evs = [
      for (final s in spots)
        if (s.heroEv != null) s.heroEv!
    ];
    if (evs.length >= 5) {
      final posCount = evs.where((e) => e >= 0).length;
      final pct = posCount / evs.length;
      if (pct >= 0.8) {
        issues.add(const PackBalanceIssue(
          type: 'ev_easy',
          description: 'EV mostly positive',
          severity: 1,
        ));
      } else if (pct <= 0.2) {
        issues.add(const PackBalanceIssue(
          type: 'ev_hard',
          description: 'EV mostly negative',
          severity: 1,
        ));
      }
    }

    return issues;
  }

  String? _heroAction(TrainingPackSpot s) {
    for (final a in s.hand.actions[0] ?? []) {
      if (a.playerIndex == s.hand.heroIndex) return a.action.toLowerCase();
    }
    return null;
  }
}
