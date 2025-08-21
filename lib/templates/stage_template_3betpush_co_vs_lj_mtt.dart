import '../models/learning_path_stage_model.dart';

/// Stage template for CO 3bet push versus LJ opens at 25bb.
const LearningPathStageModel threeBetPushCoVsLjMttStageTemplate =
    LearningPathStageModel(
      id: '3bet_push_co_vs_lj_stage',
      title: 'CO 3bet Push vs LJ 25bb',
      description: 'Decide to shove or fold from CO facing a LJ open at 25bb',
      packId: '3bet_push_co_vs_lj',
      requiredAccuracy: 80,
      minHands: 10,
      tags: ['level2', '3bet-push', 'co', 'lj', 'mtt'],
    );
