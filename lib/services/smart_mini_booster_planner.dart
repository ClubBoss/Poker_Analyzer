import '../models/theory_mini_lesson_node.dart';
import 'learning_graph_engine.dart';
import 'mini_lesson_library_service.dart';
import 'learning_path_stage_library.dart';
import 'path_map_engine.dart';

/// Suggests mini theory lessons relevant to the current learning path node.
class SmartMiniBoosterPlanner {
  final LearningPathEngine engine;
  final MiniLessonLibraryService library;
  final LearningPathStageLibrary stageLibrary;

  SmartMiniBoosterPlanner({
    LearningPathEngine? engine,
    MiniLessonLibraryService? library,
    LearningPathStageLibrary? stageLibrary,
  }) : engine = engine ?? LearningPathEngine.instance,
       library = library ?? MiniLessonLibraryService.instance,
       stageLibrary = stageLibrary ?? LearningPathStageLibrary.instance;

  static final SmartMiniBoosterPlanner instance = SmartMiniBoosterPlanner();

  /// Returns ids of mini lessons relevant to the current node using tag matching.
  Future<List<String>> getRelevantMiniLessons({int max = 2}) async {
    if (max <= 0) return [];
    final current = engine.getCurrentNode();
    if (current == null) return [];

    final tags = <String>{};

    if (current is StageNode) {
      final stage = stageLibrary.getById(current.id);
      if (stage != null) {
        for (final t in stage.tags) {
          final tag = t.trim().toLowerCase();
          if (tag.isNotEmpty) tags.add(tag);
        }
      }
    } else if (current is TheoryMiniLessonNode) {
      for (final t in current.tags) {
        final tag = t.trim().toLowerCase();
        if (tag.isNotEmpty) tags.add(tag);
      }
    }

    if (tags.isEmpty) return [];

    await library.loadAll();
    final lessons = library.getByTags(tags);
    if (lessons.isEmpty) return [];

    lessons.sort((a, b) {
      final aCount = a.tags.where((t) => tags.contains(t)).length;
      final bCount = b.tags.where((t) => tags.contains(t)).length;
      return bCount.compareTo(aCount);
    });

    return [for (final l in lessons.take(max)) l.id];
  }
}
