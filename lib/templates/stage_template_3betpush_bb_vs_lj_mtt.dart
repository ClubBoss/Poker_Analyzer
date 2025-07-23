import '../models/learning_path_stage_model.dart';

/// Stage template for BB 3bet push versus LJ opens at 25bb.
const LearningPathStageModel threeBetPushBbVsLjMttStageTemplate =
    LearningPathStageModel(
      id: '3bet_push_bb_vs_lj_stage',
      title: 'BB 3bet Push vs LJ 25bb',
      description: 'Decide to shove or fold from BB facing a LJ open at 25bb',
      packId: '3bet_push_bb_vs_lj',
      requiredAccuracy: 80,
      minHands: 10,
      tags: ['level2', '3bet-push', 'bb', 'lj', 'mtt'],
    );
