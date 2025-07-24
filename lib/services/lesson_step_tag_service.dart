import 'lesson_loader_service.dart';

/// Provides tags for each lesson step.
abstract class LessonStepTagProvider {
  Future<Map<String, List<String>>> getTagsByStepId();
}

class LessonStepTagService implements LessonStepTagProvider {
  LessonStepTagService._();
  static final instance = LessonStepTagService._();

  @override
  Future<Map<String, List<String>>> getTagsByStepId() async {
    final steps = await LessonLoaderService.instance.loadAllLessons();
    final result = <String, List<String>>{};
    for (final step in steps) {
      final tags = <String>[];
      final metaTags = step.meta['tags'];
      if (metaTags is List) {
        for (final t in metaTags) {
          final tag = t.toString().trim();
          if (tag.isNotEmpty) tags.add(tag);
        }
      } else if (metaTags is String) {
        final tag = metaTags.trim();
        if (tag.isNotEmpty) tags.add(tag);
      }
      result[step.id] = tags;
    }
    return result;
  }
}
