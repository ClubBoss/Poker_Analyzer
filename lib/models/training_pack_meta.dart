import '../core/training/engine/training_type_engine.dart';

class TrainingPackMeta {
  final String id;
  final String title;
  final String skillLevel; // e.g. beginner, intermediate, advanced
  final List<String> tags;
  final TrainingType trainingType;

  const TrainingPackMeta({
    required this.id,
    required this.title,
    required this.skillLevel,
    required this.tags,
    required this.trainingType,
  });
}
