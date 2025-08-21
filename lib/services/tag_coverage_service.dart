import 'lesson_step_tag_service.dart';

/// Computes how many lesson steps use each tag.
class TagCoverageService {
  final LessonStepTagProvider _provider;

  TagCoverageService({LessonStepTagProvider? provider})
    : _provider = provider ?? LessonStepTagService.instance;

  Future<Map<String, int>> computeTagCoverage() async {
    final tagsByStep = await _provider.getTagsByStepId();
    final result = <String, int>{};
    tagsByStep.forEach((_, tags) {
      if (tags.isEmpty) return;
      final unique = <String>{};
      for (final t in tags) {
        final tag = t.trim();
        if (tag.isEmpty) continue;
        unique.add(tag);
      }
      for (final tag in unique) {
        result[tag] = (result[tag] ?? 0) + 1;
      }
    });
    return result;
  }
}
