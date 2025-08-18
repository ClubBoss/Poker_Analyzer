enum SpotKind {
  l2_open_fold,
  l2_threebet_push,
  l2_limped,
  l4_icm,
  callVsJam,
  l3_postflop_jam,
  l3_checkraise_jam,
  l3_check_jam_vs_cbet,
  l3_donk_jam,
  l3_overbet_jam,
  l3_raise_jam_vs_donk,
  l3_bet_jam_vs_raise,
  l3_raise_jam_vs_cbet,
  l3_probe_jam_vs_raise,
  l3_river_jam_vs_bet,
  l3_turn_jam_vs_bet,
  l3_flop_jam_vs_bet,
  l3_flop_jam_vs_raise,
  l3_turn_jam_vs_raise,
  l3_river_jam_vs_raise,
  l4_icm_bubble_jam_vs_fold,
  l4_icm_ladder_jam_vs_fold,
  l4_icm_sb_jam_vs_fold,
  l4_icm_bb_jam_vs_fold,
}

const _spotKindBaseline = [
  'l2_open_fold',
  'l2_threebet_push',
  'l2_limped',
  'l4_icm',
  'callVsJam',
  'l3_postflop_jam',
  'l3_checkraise_jam',
  'l3_check_jam_vs_cbet',
  'l3_donk_jam',
  'l3_overbet_jam',
  'l3_raise_jam_vs_donk',
  'l3_bet_jam_vs_raise',
  'l3_raise_jam_vs_cbet',
  'l3_probe_jam_vs_raise',
  'l3_river_jam_vs_bet',
  'l3_turn_jam_vs_bet',
  'l3_flop_jam_vs_bet',
  'l3_flop_jam_vs_raise',
  'l3_turn_jam_vs_raise',
  'l3_river_jam_vs_raise',
  'l4_icm_bubble_jam_vs_fold',
  'l4_icm_ladder_jam_vs_fold',
  'l4_icm_sb_jam_vs_fold',
  'l4_icm_bb_jam_vs_fold',
];

final _spotKindGuard = () {
  assert(() {
    final names = SpotKind.values.map((e) => e.name).toList();
    if (names.length < _spotKindBaseline.length) {
      throw 'SpotKind must be append-only: do not rename/reorder; only append at the end (with trailing comma).';
    }
    for (var i = 0; i < _spotKindBaseline.length; i++) {
      if (names[i] != _spotKindBaseline[i]) {
        throw 'SpotKind must be append-only: do not rename/reorder; only append at the end (with trailing comma).';
      }
    }
    return true;
  }());
}();

class UiSpot {
  final SpotKind kind;
  final String hand;
  final String pos;
  final String stack;
  final String action;
  final String? vsPos;
  final String? limpers;
  final String? explain;

  const UiSpot({
    required this.kind,
    required this.hand,
    required this.pos,
    required this.stack,
    required this.action,
    this.vsPos,
    this.limpers,
    this.explain,
  });
}

class UiAnswer {
  final bool correct;
  final String expected;
  final String chosen;
  final Duration elapsed;

  const UiAnswer({
    required this.correct,
    required this.expected,
    required this.chosen,
    required this.elapsed,
  });
}
