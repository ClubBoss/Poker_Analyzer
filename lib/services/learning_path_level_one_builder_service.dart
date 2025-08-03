import '../models/learning_path_node_v2.dart';

class LearningPathLevelOneBuilderService {
  const LearningPathLevelOneBuilderService();

  List<LearningPathNodeV2> build() {
    return const [
      LearningPathNodeV2.theory(
        id: 'lesson_push_fold_intro',
        miniLessonId: 'lesson_push_fold_intro',
      ),
      LearningPathNodeV2.training(
        id: 'pack_intro_push_fold_mtt',
        trainingPackTemplateId: 'pack_intro_push_fold_mtt',
      ),
      LearningPathNodeV2.theory(
        id: 'lesson_ranges_vs_bb',
        miniLessonId: 'lesson_ranges_vs_bb',
      ),
      LearningPathNodeV2.training(
        id: 'pack_ranges_vs_bb',
        trainingPackTemplateId: 'pack_ranges_vs_bb',
      ),
      LearningPathNodeV2.theory(
        id: 'lesson_ranges_vs_sb',
        miniLessonId: 'lesson_ranges_vs_sb',
      ),
      LearningPathNodeV2.training(
        id: 'pack_ranges_vs_sb',
        trainingPackTemplateId: 'pack_ranges_vs_sb',
      ),
      LearningPathNodeV2.theory(
        id: 'lesson_ranges_vs_button',
        miniLessonId: 'lesson_ranges_vs_button',
      ),
      LearningPathNodeV2.training(
        id: 'pack_ranges_vs_button',
        trainingPackTemplateId: 'pack_ranges_vs_button',
      ),
      LearningPathNodeV2.theory(
        id: 'lesson_traps_and_exploit',
        miniLessonId: 'lesson_traps_and_exploit',
      ),
      LearningPathNodeV2.training(
        id: 'pack_final_challenge',
        trainingPackTemplateId: 'pack_final_challenge',
      ),
    ];
  }
}
