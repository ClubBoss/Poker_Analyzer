import '../models/learning_path_stage_model.dart';

/// Stage template for BTN 3bet push versus SB opens at 25bb.
const LearningPathStageModel threeBetPushBtnVsSbMttStageTemplate =
    LearningPathStageModel(
      id: '3bet_push_btn_vs_sb_stage',
      title: 'BTN 3bet Push vs SB 25bb',
      description: 'Decide to shove or fold from BTN facing a SB open at 25bb',
      packId: '3bet_push_btn_vs_sb',
      requiredAccuracy: 80,
      minHands: 10,
      tags: ['level2', '3bet-push', 'btn', 'sb', 'mtt'],
    );
