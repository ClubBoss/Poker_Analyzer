import '../models/learning_path_stage_model.dart';

/// Stage template for UTG open/fold decisions in MTTs.
const LearningPathStageModel openFoldUtgMttStageTemplate =
    LearningPathStageModel(
      id: 'open_fold_utg_mtt_stage',
      title: 'UTG Open/Fold 15-25bb',
      description:
          'Decide whether to open or fold from UTG when everyone folds to you',
      packId: 'open_fold_utg_mtt',
      requiredAccuracy: 80,
      minHands: 10,
      tags: ['level2', 'mtt', 'utg', 'openfold'],
    );
