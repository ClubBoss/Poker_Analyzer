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
  l3_raise_jam_vs_donk
}

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
