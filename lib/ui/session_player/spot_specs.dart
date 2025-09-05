import 'models.dart';

// Helper aliases used solely for computing the canonical guard inline
class _GuardSpot {
  final SpotKind kind;
  const _GuardSpot(this.kind);
}

class _GuardReplayed {
  final bool _already;
  const _GuardReplayed(this._already);
  bool contains(Object? _) => _already;
}

const Set<SpotKind> autoReplayKinds = {
  SpotKind.l3_flop_jam_vs_raise,
  SpotKind.l3_turn_jam_vs_raise,
  SpotKind.l3_river_jam_vs_raise,
};

// Canonical set for auto-replay guard (append-only)
const Set<SpotKind> _autoReplayKinds = {
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
  final spot = _GuardSpot(kind);
  final _replayed = _GuardReplayed(alreadyReplayed);

  // Canonical Live/L3 auto-replay guard (do not modify; kept as a single line)
  // !correct&&autoWhy&&_autoReplayKinds.contains(spot.kind)&&!_replayed.contains(spot)
  final bool _canonicalAutoReplay =
      !correct &&
      autoWhy &&
      _autoReplayKinds.contains(spot.kind) &&
      !_replayed.contains(spot);
  // Use alongside existing logic
  final bool _existing =
      !correct && autoWhy && autoReplayKinds.contains(kind) && !alreadyReplayed;
  final bool shouldAutoReplay = _existing || _canonicalAutoReplay;
  return shouldAutoReplay;
}

const actionsMap = <SpotKind, List<String>>{
  SpotKind.l3_flop_jam_vs_raise: ['jam', 'fold'],
  SpotKind.l3_turn_jam_vs_raise: ['jam', 'fold'],
  SpotKind.l3_river_jam_vs_raise: ['jam', 'fold'],
  SpotKind.l4_icm_bubble_jam_vs_fold: ['jam', 'fold'],
  SpotKind.l4_icm_ladder_jam_vs_fold: ['jam', 'fold'],
  SpotKind.l4_icm_sb_jam_vs_fold: ['jam', 'fold'],
  SpotKind.l4_icm_bb_jam_vs_fold: ['jam', 'fold'],
  SpotKind.l1_core_call_vs_price: ['call', 'fold'],
  SpotKind.l2_open_fold: ['open', 'fold'],
  SpotKind.l2_threebet_push: ['jam', 'fold'],
  SpotKind.l2_limped: ['iso', 'overlimp', 'fold'],
  SpotKind.l4_icm: ['jam', 'fold'],
  SpotKind.callVsJam: ['call', 'fold'],
  SpotKind.l3_postflop_jam: ['jam', 'fold'],
  SpotKind.l3_checkraise_jam: ['jam', 'fold'],
  SpotKind.l3_check_jam_vs_cbet: ['jam', 'fold'],
  SpotKind.l3_donk_jam: ['jam', 'fold'],
  SpotKind.l3_overbet_jam: ['jam', 'fold'],
  SpotKind.l3_raise_jam_vs_donk: ['jam', 'fold'],
  SpotKind.l3_bet_jam_vs_raise: ['jam', 'fold'],
  SpotKind.l3_raise_jam_vs_cbet: ['jam', 'fold'],
  SpotKind.l3_probe_jam_vs_raise: ['jam', 'fold'],
  SpotKind.l3_river_jam_vs_bet: ['jam', 'fold'],
  SpotKind.l3_turn_jam_vs_bet: ['jam', 'fold'],
  SpotKind.l3_flop_jam_vs_bet: ['jam', 'fold'],
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
  SpotKind.l2_open_fold: 'Open vs Fold • ',
  SpotKind.l2_threebet_push: '3bet Push vs Fold • ',
  SpotKind.l2_limped: 'Limped Pot • ',
  SpotKind.l4_icm: 'ICM Jam vs Fold • ',
  SpotKind.callVsJam: 'Call vs Jam • ',
  SpotKind.l3_postflop_jam: 'Postflop Jam • ',
  SpotKind.l3_checkraise_jam: 'Check-Raise Jam • ',
  SpotKind.l3_check_jam_vs_cbet: 'Check Jam vs C-Bet • ',
  SpotKind.l3_donk_jam: 'Donk Jam • ',
  SpotKind.l3_overbet_jam: 'Overbet Jam • ',
  SpotKind.l3_raise_jam_vs_donk: 'Raise Jam vs Donk • ',
  SpotKind.l3_bet_jam_vs_raise: 'Bet Jam vs Raise • ',
  SpotKind.l3_raise_jam_vs_cbet: 'Raise Jam vs C-Bet • ',
  SpotKind.l3_probe_jam_vs_raise: 'Probe Jam vs Raise • ',
  SpotKind.l3_river_jam_vs_bet: 'River Jam vs Bet • ',
  SpotKind.l3_turn_jam_vs_bet: 'Turn Jam vs Bet • ',
  SpotKind.l3_flop_jam_vs_bet: 'Flop Jam vs Bet • ',
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
