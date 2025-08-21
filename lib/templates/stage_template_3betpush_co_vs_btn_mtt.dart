import '../models/learning_path_stage_model.dart';

/// Stage template for CO 3bet push versus BTN opens at 25bb.
const LearningPathStageModel threeBetPushCoVsBtnMttStageTemplate =
    LearningPathStageModel(
      id: '3bet_push_co_vs_btn_stage',
      title: 'CO 3bet Push vs BTN 25bb',
      description: 'Decide to shove or fold from CO facing a BTN open at 25bb',
      packId: '3bet_push_co_vs_btn',
      requiredAccuracy: 80,
      minHands: 10,
      tags: ['level2', '3bet-push', 'co', 'btn', 'mtt'],
    );
