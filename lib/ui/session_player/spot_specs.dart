import 'models.dart';

const autoReplayKinds = {
  SpotKind.l3_flop_jam_vs_raise,
  SpotKind.l3_turn_jam_vs_raise,
  SpotKind.l3_river_jam_vs_raise,
  SpotKind.l4_icm_bubble_jam_vs_fold,
  SpotKind.l4_icm_ladder_jam_vs_fold,
  SpotKind.l4_icm_sb_jam_vs_fold,
};

const actionsMap = <SpotKind, List<String>>{
  SpotKind.l3_flop_jam_vs_raise: ['jam', 'fold'],
  SpotKind.l3_turn_jam_vs_raise: ['jam', 'fold'],
  SpotKind.l3_river_jam_vs_raise: ['jam', 'fold'],
  SpotKind.l4_icm_bubble_jam_vs_fold: ['jam', 'fold'],
  SpotKind.l4_icm_ladder_jam_vs_fold: ['jam', 'fold'],
  SpotKind.l4_icm_sb_jam_vs_fold: ['jam', 'fold'],
};

const subtitlePrefix = <SpotKind, String>{
  SpotKind.l3_flop_jam_vs_raise: 'Flop Jam vs Raise • ',
  SpotKind.l3_turn_jam_vs_raise: 'Turn Jam vs Raise • ',
  SpotKind.l3_river_jam_vs_raise: 'River Jam vs Raise • ',
  SpotKind.l4_icm_bubble_jam_vs_fold: 'ICM Bubble Jam vs Fold • ',
  SpotKind.l4_icm_ladder_jam_vs_fold: 'ICM FT Ladder Jam vs Fold • ',
  SpotKind.l4_icm_sb_jam_vs_fold: 'ICM SB Jam vs Fold • ',
};
