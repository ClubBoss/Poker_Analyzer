import '../models/learning_path_stage_model.dart';

/// Stage template for LJ open/fold decisions in MTTs.
const LearningPathStageModel openFoldLjMttStageTemplate =
    LearningPathStageModel(
      id: 'open_fold_lj_mtt_stage',
      title: 'LJ Open/Fold 25bb',
      description:
          'Decide whether to open or fold from LJ when everyone folds to you',
      packId: 'open_fold_lj_mtt',
      requiredAccuracy: 80,
      minHands: 10,
      tags: ['level2', 'mtt', 'lj', 'openfold'],
    );
