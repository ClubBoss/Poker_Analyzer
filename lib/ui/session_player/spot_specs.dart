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
  return !correct && autoWhy && autoReplayKinds.contains(kind) && !alreadyReplayed;
}

const actionsMap = <SpotKind, List<String>>{
  SpotKind.l3_flop_jam_vs_raise: ['jam', 'fold'],
  SpotKind.l3_turn_jam_vs_raise: ['jam', 'fold'],
  SpotKind.l3_river_jam_vs_raise: ['jam', 'fold'],
  SpotKind.l4_icm_bubble_jam_vs_fold: ['jam', 'fold'],
  SpotKind.l4_icm_ladder_jam_vs_fold: ['jam', 'fold'],
  SpotKind.l4_icm_sb_jam_vs_fold: const ['jam', 'fold'],
  SpotKind.l4_icm_bb_jam_vs_fold: const ['jam', 'fold'],
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
};
