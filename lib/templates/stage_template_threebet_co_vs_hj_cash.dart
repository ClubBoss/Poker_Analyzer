import '../models/learning_path_stage_model.dart';

/// Stage template for CO 3-bet or fold decisions facing a HJ 3bb open in 6-max cash games.
const LearningPathStageModel
threeBetCoVsHjCashStageTemplate = LearningPathStageModel(
  id: 'threebet_co_vs_hj_cash',
  title: 'CO vs HJ 3-bet (Cash)',
  description:
      'Decide whether to 3-bet or fold from the Cutoff facing a Hijack 3bb open in 6-max cash games',
  packId: 'threebet_co_vs_hj_cash',
  requiredAccuracy: 80,
  minHands: 10,
  tags: ['threebet', 'cash', 'preflop', 'level2', 'co', 'vsHj'],
  unlocks: ['threebet_hj_vs_utg_cash'],
);
