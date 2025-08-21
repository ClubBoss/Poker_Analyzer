import '../models/theory_mini_lesson_node.dart';
import '../models/v2/training_spot_v2.dart';
import 'mini_lesson_library_service.dart';
import 'mini_lesson_progress_tracker.dart';
import 'theory_mini_lesson_linker.dart';

/// Suggests mini theory lessons after a mistake based on spot tags and stage.
class TheoryBoosterSuggestionService {
  final TheoryMiniLessonLinker linker;
  final MiniLessonLibraryService library;
  final MiniLessonProgressTracker progress;

  TheoryBoosterSuggestionService({
    TheoryMiniLessonLinker? linker,
    MiniLessonLibraryService? library,
    MiniLessonProgressTracker? progress,
  })  : linker = linker ?? const TheoryMiniLessonLinker(),
        library = library ?? MiniLessonLibraryService.instance,
        progress = progress ?? MiniLessonProgressTracker.instance;

  static final TheoryBoosterSuggestionService instance =
      TheoryBoosterSuggestionService();

  static final RegExp _stageRe = RegExp(r'^level\\d+\$', caseSensitive: false);

  bool _isStageTag(String tag) => _stageRe.hasMatch(tag);

  String? _extractStage(Iterable<String> tags) {
    for (final t in tags) {
      final lc = t.toLowerCase().trim();
      if (_isStageTag(lc)) return lc;
    }
    return null;
  }

  /// Returns up to two theory lessons relevant to [spot].
  Future<List<TheoryMiniLessonNode>> suggestForSpot(TrainingSpotV2 spot) async {
    await linker.link();
    await library.loadAll();

    final tags = {for (final t in spot.tags) t.toLowerCase().trim()}
      ..removeWhere(_isStageTag);
    final stage = _extractStage(spot.tags);

    final candidates = <MapEntry<TheoryMiniLessonNode, int>>[];

    for (final lesson in library.all) {
      if (stage != null) {
        final lessonStage =
            lesson.stage?.toLowerCase() ?? _extractStage(lesson.tags);
        if (lessonStage != null && lessonStage != stage) continue;
      }
      final lessonTags = {for (final t in lesson.tags) t.toLowerCase().trim()}
        ..removeWhere(_isStageTag);
      final overlap = lessonTags.intersection(tags).length;
      if (overlap == 0) continue;
      if (await progress.isCompleted(lesson.id)) continue;
      candidates.add(MapEntry(lesson, overlap));
    }

    if (candidates.isEmpty) return [];
    candidates.sort((a, b) => b.value.compareTo(a.value));
    return [for (final c in candidates.take(2)) c.key];
  }
}
