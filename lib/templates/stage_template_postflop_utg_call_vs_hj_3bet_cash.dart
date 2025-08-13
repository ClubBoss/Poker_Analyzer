import '../models/learning_path_stage_model.dart';

/// Stage template for UTG postflop decisions after calling an HJ 3-bet in 6-max cash games.
const LearningPathStageModel postflopUtgCallVsHj3betCashStageTemplate =
    LearningPathStageModel(
  id: 'postflop_utg_call_vs_hj_3bet_cash',
  title: 'UTG Postflop vs HJ 3-bet (Cash)',
  description:
      'Play OOP after calling an HJ 3-bet; handle range disadvantage, board interaction, and lost initiative',
  packId: 'postflop_utg_call_vs_hj_3bet_cash',
  requiredAccuracy: 80,
  minHands: 10,
  tags: ['threebetDefense', 'cash', 'postflop', 'level3', 'utg', 'vsHj'],
);
