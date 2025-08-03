import 'learning_path_node.dart';

enum LearningPathNodeType { theory, training }

class LearningPathNodeV2 implements LearningPathNode {
  @override
  final String id;
  final LearningPathNodeType type;
  final String? miniLessonId;
  final String? trainingPackTemplateId;

  @override
  final bool recoveredFromMistake;

  const LearningPathNodeV2.theory({
    required this.id,
    required String miniLessonId,
    this.recoveredFromMistake = false,
  })  : type = LearningPathNodeType.theory,
        miniLessonId = miniLessonId,
        trainingPackTemplateId = null;

  const LearningPathNodeV2.training({
    required this.id,
    required String trainingPackTemplateId,
    this.recoveredFromMistake = false,
  })  : type = LearningPathNodeType.training,
        miniLessonId = null,
        trainingPackTemplateId = trainingPackTemplateId;
}
