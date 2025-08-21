import '../models/learning_path_stage_model.dart';

/// Stage template for SB 3bet push versus LJ opens at 25bb.
const LearningPathStageModel threeBetPushSbVsLjMttStageTemplate =
    LearningPathStageModel(
  id: '3bet_push_sb_vs_lj_stage',
  title: 'SB 3bet Push vs LJ 25bb',
  description: 'Decide to shove or fold from SB facing a LJ open at 25bb',
  packId: '3bet_push_sb_vs_lj',
  requiredAccuracy: 80,
  minHands: 10,
  tags: ['level2', '3bet-push', 'sb', 'lj', 'mtt'],
);
