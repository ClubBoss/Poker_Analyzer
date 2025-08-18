import '../models/learning_path_stage_model.dart';

/// Stage template for SB 3bet push versus BTN opens at 25bb.
const LearningPathStageModel threeBetPushSbVsBtnMttStageTemplate =
    LearningPathStageModel(
      id: '3bet_push_sb_vs_btn_stage',
      title: 'SB 3bet Push vs BTN 25bb',
      description: 'Decide to shove or fold from SB facing a BTN open at 25bb',
      packId: '3bet_push_sb_vs_btn',
      requiredAccuracy: 80,
      minHands: 10,
      tags: ['level2', '3bet-push', 'sb', 'btn', 'mtt'],
    );
