import '../models/learning_path_stage_model.dart';

/// Stage template for UTG call or fold decisions facing an HJ 3-bet in 6-max cash games.
const LearningPathStageModel defendUtgVsHj3betCashStageTemplate = LearningPathStageModel(
  id: 'defend_utg_vs_hj_3bet_cash',
  title: 'UTG Defense vs HJ 3-bet (Cash)',
  description: 'Decide whether to call or fold from UTG facing a Hijack 3-bet in 6-max cash games',
  packId: 'defend_utg_vs_hj_3bet_cash',
  requiredAccuracy: 80,
  minHands: 10,
  tags: ['threebetDefense', 'cash', 'preflop', 'level2', 'utg', 'vsHj'],
  unlocks: ['postflop_utg_call_vs_hj_3bet_cash'],
);
