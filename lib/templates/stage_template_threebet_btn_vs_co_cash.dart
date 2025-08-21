import '../models/learning_path_stage_model.dart';

/// Stage template for BTN 3-bet or fold decisions facing a CO 3bb open in 6-max cash games.
const LearningPathStageModel threeBetBtnVsCoCashStageTemplate =
    LearningPathStageModel(
  id: 'threebet_btn_vs_co_cash',
  title: 'BTN vs CO 3-bet (Cash)',
  description:
      'Decide whether to 3-bet or fold from the Button facing a Cutoff 3bb open in 6-max cash games',
  packId: 'threebet_btn_vs_co_cash',
  requiredAccuracy: 80,
  minHands: 10,
  tags: ['threebet', 'cash', 'preflop', 'level2', 'btn', 'vsCo'],
  unlocks: ['threebet_co_vs_hj_cash'],
);
