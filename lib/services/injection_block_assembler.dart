import '../models/theory_mini_lesson_node.dart';
import '../models/learning_path_block.dart';

/// Builds [LearningPathBlock]s from injected mini lessons.
class InjectionBlockAssembler {
  InjectionBlockAssembler();

  /// Creates a [LearningPathBlock] presentation for [lesson].
  LearningPathBlock build(
    TheoryMiniLessonNode lesson,
    String injectedInStageId,
  ) {
    final header = 'Краткий разбор: ${lesson.resolvedTitle}';
    final summary = _shorten(lesson.resolvedContent);
    return LearningPathBlock(
      id: lesson.id,
      header: header,
      content: summary,
      ctaLabel: 'Читать подробнее',
      lessonId: lesson.id,
      injectedInStageId: injectedInStageId,
    );
  }

  String _shorten(String text, {int maxLen = 300}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    final parts = trimmed.split(RegExp(r'\n\n+'));
    var first = parts.first.trim();
    if (first.length > maxLen) {
      first = first.substring(0, maxLen).trim();
      if (!first.endsWith('...')) {
        first = '$first...';
      }
    }
    return first;
  }
}
