import '../models/learning_path_stage_model.dart';

/// Stage template for SB 3bet push versus CO opens at 25bb.
const LearningPathStageModel threeBetPushSbVsCoMttStageTemplate =
    LearningPathStageModel(
  id: '3bet_push_sb_vs_co_stage',
  title: 'SB 3bet Push vs CO 25bb',
  description: 'Decide to shove or fold from SB facing a CO open at 25bb',
  packId: '3bet_push_sb_vs_co',
  requiredAccuracy: 80,
  minHands: 10,
  tags: ['level2', '3bet-push', 'sb', 'co', 'mtt'],
);
