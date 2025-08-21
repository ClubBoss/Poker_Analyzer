import '../models/learning_path_stage_model.dart';

/// Stage template for HJ open/fold decisions facing an UTG 3bb raise in 6-max cash games.
const LearningPathStageModel openFoldHjVsUtgCashStageTemplate =
    LearningPathStageModel(
  id: 'openfold_hj_vs_utg_cash',
  title: 'HJ vs UTG Open/Fold (Cash)',
  description:
      'Decide whether to 3-bet or fold the Hijack facing an UTG 3bb open in 6-max cash games',
  packId: 'openfold_hj_vs_utg_cash',
  requiredAccuracy: 80,
  minHands: 10,
  tags: ['openfold', 'cash', 'preflop', 'level2', 'hj', 'vsUtg'],
  unlocks: ['threebet_btn_vs_co_cash'],
);
