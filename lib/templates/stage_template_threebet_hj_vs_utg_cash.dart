import '../models/learning_path_stage_model.dart';

/// Stage template for HJ 3-bet or fold decisions facing an UTG 3bb open in 6-max cash games.
const LearningPathStageModel
threeBetHjVsUtgCashStageTemplate = LearningPathStageModel(
  id: 'threebet_hj_vs_utg_cash',
  title: 'HJ vs UTG 3-bet (Cash)',
  description:
      'Decide whether to 3-bet or fold from the Hijack facing an UTG 3bb open in 6-max cash games',
  packId: 'threebet_hj_vs_utg_cash',
  requiredAccuracy: 80,
  minHands: 10,
  tags: ['threebet', 'cash', 'preflop', 'level2', 'hj', 'vsUtg'],
  unlocks: ['defend_utg_vs_hj_3bet_cash'],
);
