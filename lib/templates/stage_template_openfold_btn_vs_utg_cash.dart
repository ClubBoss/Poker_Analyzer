import '../models/learning_path_stage_model.dart';

/// Stage template for BTN open/fold decisions facing a UTG 3bb raise in 6-max cash games.
const LearningPathStageModel openFoldBtnVsUtgCashStageTemplate = LearningPathStageModel(
  id: 'openfold_btn_vs_utg_cash',
  title: 'BTN vs UTG Open/Fold (Cash)',
  description: 'Decide whether to 3-bet or fold the Button facing an UTG 3bb open in 6-max cash games',
  packId: 'openfold_btn_vs_utg_cash',
  requiredAccuracy: 80,
  minHands: 10,
  tags: ['openfold', 'cash', 'preflop', 'level2', 'btn', 'vsUtg'],
);

