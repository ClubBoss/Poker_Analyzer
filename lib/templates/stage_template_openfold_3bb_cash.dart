import '../models/learning_path_stage_model.dart';

/// Stage template for open/fold decisions versus a 3bb raise in 6-max cash games.
const LearningPathStageModel openFold3bbCashStageTemplate =
    LearningPathStageModel(
  id: 'openfold_3bb_cash',
  title: 'Open/Fold vs 3bb Raise (Cash)',
  description:
      'Decide whether to open or fold facing a standard 3bb raise in 6-max cash games',
  packId: 'openfold_3bb_cash',
  requiredAccuracy: 80,
  minHands: 10,
  tags: ['openfold', 'cash', 'preflop', 'level2'],
  unlocks: ['openfold_btn_vs_utg_cash'],
);
