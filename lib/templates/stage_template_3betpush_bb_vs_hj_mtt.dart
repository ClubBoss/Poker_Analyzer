import '../models/learning_path_stage_model.dart';

/// Stage template for BB 3bet push versus HJ opens at 25bb.
const LearningPathStageModel threeBetPushBbVsHjMttStageTemplate =
    LearningPathStageModel(
      id: '3bet_push_bb_vs_hj_stage',
      title: 'BB 3bet Push vs HJ 25bb',
      description: 'Decide to shove or fold from BB facing a HJ open at 25bb',
      packId: '3bet_push_bb_vs_hj',
      requiredAccuracy: 80,
      minHands: 10,
      tags: ['level2', '3bet-push', 'bb', 'hj', 'mtt'],
    );
