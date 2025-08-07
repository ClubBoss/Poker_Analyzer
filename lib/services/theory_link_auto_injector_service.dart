import 'package:flutter/foundation.dart';

import '../models/v2/training_pack_spot.dart';
import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';

/// Automatically links training spots with relevant theory mini lessons based
/// on shared tags.
class TheoryLinkAutoInjectorService {
  final MiniLessonLibraryService library;

  TheoryLinkAutoInjectorService({MiniLessonLibraryService? library})
    : library = library ?? MiniLessonLibraryService.instance;

  /// Enriches [spots] with a `linkedTheoryLessonId` meta field when a matching
  /// [TheoryMiniLessonNode] exists.
  ///
  /// Returns the number of spots that received links.
  Future<int> injectLinks(
    List<TrainingPackSpot> spots, {
    List<TheoryMiniLessonNode>? lessons,
  }) async {
    final lessonList = lessons ?? await _loadLessons();
    int injected = 0;
    for (final spot in spots) {
      if (spot.meta.containsKey('linkedTheoryLessonId')) continue;
      final lesson = _findBestMatch(spot, lessonList);
      if (lesson == null) continue;
      spot.meta['linkedTheoryLessonId'] = lesson.id;
      injected++;
    }
    debugPrint('TheoryLinkAutoInjectorService: injected $injected links');
    return injected;
  }

  Future<List<TheoryMiniLessonNode>> _loadLessons() async {
    await library.loadAll();
    return library.all;
  }

  TheoryMiniLessonNode? _findBestMatch(
    TrainingPackSpot spot,
    List<TheoryMiniLessonNode> lessons,
  ) {
    TheoryMiniLessonNode? best;
    int bestOverlap = 0;
    final spotTags = spot.tags.toSet();
    for (final lesson in lessons) {
      final overlap = spotTags.intersection(lesson.tags.toSet()).length;
      if (overlap > bestOverlap) {
        bestOverlap = overlap;
        best = lesson;
      }
    }
    return best;
  }
}
