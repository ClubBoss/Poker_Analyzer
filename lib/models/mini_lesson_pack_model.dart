import 'theory_mini_lesson_node.dart';

/// Representation of a mini lesson pack loaded from YAML.
class MiniLessonPackModel {
  final String packId;
  final String title;
  final String type;
  final List<TheoryMiniLessonNode> lessons;

  MiniLessonPackModel({
    required this.packId,
    required this.title,
    required this.type,
    List<TheoryMiniLessonNode>? lessons,
  }) : lessons = lessons ?? const [];

  factory MiniLessonPackModel.fromYaml(Map yaml) {
    final lessons = <TheoryMiniLessonNode>[];
    final rawLessons = yaml['lessons'];
    if (rawLessons is List) {
      for (final l in rawLessons) {
        if (l is Map) {
          lessons.add(
            TheoryMiniLessonNode.fromYaml(Map<String, dynamic>.from(l)),
          );
        }
      }
    }
    return MiniLessonPackModel(
      packId: yaml['pack_id']?.toString() ?? '',
      title: yaml['title']?.toString() ?? '',
      type: yaml['type']?.toString() ?? '',
      lessons: lessons,
    );
  }
}
