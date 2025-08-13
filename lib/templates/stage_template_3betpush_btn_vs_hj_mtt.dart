import '../models/learning_path_stage_model.dart';

/// Stage template for BTN 3bet push versus HJ opens at 25bb.
const LearningPathStageModel threeBetPushBtnVsHjMttStageTemplate =
    LearningPathStageModel(
  id: '3bet_push_btn_vs_hj_stage',
  title: 'BTN 3bet Push vs HJ 25bb',
  description: 'Decide to shove or fold from BTN facing a HJ open at 25bb',
  packId: '3bet_push_btn_vs_hj',
  requiredAccuracy: 80,
  minHands: 10,
  tags: ['level2', '3bet-push', 'btn', 'hj', 'mtt'],
);
