import '../models/learning_path_stage_model.dart';

/// Stage template for SB 3bet push versus HJ opens at 25bb.
const LearningPathStageModel threeBetPushSbVsHjMttStageTemplate =
    LearningPathStageModel(
  id: '3bet_push_sb_vs_hj_stage',
  title: 'SB 3bet Push vs HJ 25bb',
  description: 'Decide to shove or fold from SB facing a HJ open at 25bb',
  packId: '3bet_push_sb_vs_hj',
  requiredAccuracy: 80,
  minHands: 10,
  tags: ['level2', '3bet-push', 'sb', 'hj', 'mtt'],
);
