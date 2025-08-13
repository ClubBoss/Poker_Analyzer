import '../models/learning_path_stage_model.dart';

/// Stage template for BTN 3bet push versus LJ opens at 25bb.
const LearningPathStageModel threeBetPushBtnVsLjMttStageTemplate =
    LearningPathStageModel(
  id: '3bet_push_btn_vs_lj_stage',
  title: 'BTN 3bet Push vs LJ 25bb',
  description: 'Decide to shove or fold from BTN facing a LJ open at 25bb',
  packId: '3bet_push_btn_vs_lj',
  requiredAccuracy: 80,
  minHands: 10,
  tags: ['level2', '3bet-push', 'btn', 'lj'],
);
