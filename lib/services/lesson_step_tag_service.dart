import '../models/v3/lesson_step.dart';
import 'lesson_loader_service.dart';

class LessonStepTagService {
  LessonStepTagService._();
  static final instance = LessonStepTagService._();

  Future<Map<String, List<String>>> getTagsByStepId() async {
    final steps = await LessonLoaderService.instance.loadAllLessons();
    final result = <String, List<String>>{};
    for (final step in steps) {
      final tags = step.tags;
      if (tags == null || tags.isEmpty) continue;
      result[step.id] = List<String>.from(tags);
    }
    return result;
  }
}
