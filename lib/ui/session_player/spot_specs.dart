import 'models.dart';

const Set<SpotKind> autoReplayKinds = {
  SpotKind.l3_flop_jam_vs_raise,
  SpotKind.l3_turn_jam_vs_raise,
  SpotKind.l3_river_jam_vs_raise,
};

bool shouldAutoReplay({
  required bool correct,
  required bool autoWhy,
  required SpotKind kind,
  required bool alreadyReplayed,
}) {
  return !correct &&
      autoWhy &&
      autoReplayKinds.contains(kind) &&
      !alreadyReplayed;
}

const actionsMap = <SpotKind, List<String>>{
  SpotKind.l3_flop_jam_vs_raise: ['jam', 'fold'],
  SpotKind.l3_turn_jam_vs_raise: ['jam', 'fold'],
  SpotKind.l3_river_jam_vs_raise: ['jam', 'fold'],
  SpotKind.l4_icm_bubble_jam_vs_fold: ['jam', 'fold'],
  SpotKind.l4_icm_ladder_jam_vs_fold: ['jam', 'fold'],
  SpotKind.l4_icm_sb_jam_vs_fold: ['jam', 'fold'],
  SpotKind.l4_icm_bb_jam_vs_fold: ['jam', 'fold'],
  SpotKind.l1_core_call_vs_price: ['jam', 'fold'],
};

bool isJamFold(SpotKind k) {
  final a = actionsMap[k];
  return a != null && a.length == 2 && a[0] == 'jam' && a[1] == 'fold';
}

String jamDedupKey(UiSpot s) =>
    '${s.kind.name}|${s.hand}|${s.pos}|${s.vsPos ?? ''}|${s.stack}';

const subtitlePrefix = <SpotKind, String>{
  SpotKind.l3_flop_jam_vs_raise: 'Flop Jam vs Raise • ',
  SpotKind.l3_turn_jam_vs_raise: 'Turn Jam vs Raise • ',
  SpotKind.l3_river_jam_vs_raise: 'River Jam vs Raise • ',
  SpotKind.l4_icm_bubble_jam_vs_fold: 'ICM Bubble Jam vs Fold • ',
  SpotKind.l4_icm_ladder_jam_vs_fold: 'ICM FT Ladder Jam vs Fold • ',
  SpotKind.l4_icm_sb_jam_vs_fold: 'ICM SB Jam vs Fold • ',
  SpotKind.l4_icm_bb_jam_vs_fold: 'ICM BB Jam vs Fold • ',
  SpotKind.l1_core_call_vs_price: 'Pot Odds • ',
};

// SSOT for Ladder pass criteria
const int ladderPassAccPct = 80; // percent
const int ladderPassAvgMs = 1800; // per-spot average

class LadderOutcome {
  final bool passed;
  final double accPct;
  final int avgMs;
  final int total;
  const LadderOutcome({
    required this.passed,
    required this.accPct,
    required this.avgMs,
    required this.total,
  });
}

/// Computes summary metrics for a finished session and applies Ladder thresholds.
/// Pure Dart; safe for tests without Flutter.
LadderOutcome computeLadderOutcome(List<UiAnswer> answers) {
  final total = answers.length;
  final correct = answers.where((a) => a.correct).length;
  final accPct = total == 0 ? 0.0 : (correct * 100.0) / total;
  final avgMs = total == 0
      ? 0
      : (answers
                .map((a) => a.elapsed)
                .fold(Duration.zero, (a, b) => a + b)
                .inMilliseconds ~/
            total);
  final passed = accPct >= ladderPassAccPct && avgMs <= ladderPassAvgMs;
  return LadderOutcome(
    passed: passed,
    accPct: accPct,
    avgMs: avgMs,
    total: total,
  );
}
