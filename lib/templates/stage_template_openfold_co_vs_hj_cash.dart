import '../models/learning_path_stage_model.dart';

/// Stage template for CO open/fold decisions facing a HJ 3bb raise in 6-max cash games.
const LearningPathStageModel openFoldCoVsHjCashStageTemplate =
    LearningPathStageModel(
  id: 'openfold_co_vs_hj_cash',
  title: 'CO vs HJ Open/Fold (Cash)',
  description:
      'Decide whether to 3-bet or fold the Cutoff facing a Hijack 3bb open in 6-max cash games',
  packId: 'openfold_co_vs_hj_cash',
  requiredAccuracy: 80,
  minHands: 10,
  tags: ['openfold', 'cash', 'preflop', 'level2', 'co', 'vsHj'],
  unlocks: ['openfold_hj_vs_utg_cash'],
);
