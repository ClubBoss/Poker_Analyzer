import 'package:collection/collection.dart';

import '../models/skill_tag_coverage_report.dart';
import '../models/training_pack_model.dart';
import '../models/v2/training_pack_spot.dart';
import 'mini_lesson_library_service.dart';
import 'theory_mini_lesson_navigator.dart';
import 'inline_theory_linker.dart';
import '../models/theory_mini_lesson_node.dart';

/// Injects [InlineTheoryLink]s into [TrainingPackSpot]s based on
/// underrepresented skill tags.
class TheoryLinkAutoInjectorService {
  TheoryLinkAutoInjectorService({
    MiniLessonLibraryService? library,
    TheoryMiniLessonNavigator? navigator,
    this.maxRefsPerSpot = 3,
  })  : _library = library ?? MiniLessonLibraryService.instance,
        _navigator = navigator ?? TheoryMiniLessonNavigator.instance;

  final MiniLessonLibraryService _library;
  final TheoryMiniLessonNavigator _navigator;
  final int maxRefsPerSpot;

  /// Scans all [packs] and attaches theory links to spots that contain tags
  /// listed in [report.underrepresentedTags].
  ///
  /// Spots with an existing [TrainingPackSpot.theoryLink] remain unchanged.
  List<TrainingPackModel> injectLinks(
    SkillTagCoverageReport report,
    List<TrainingPackModel> packs,
  ) {
    final under = report.underrepresentedTags.toSet();
    for (final pack in packs) {
      for (final spot in pack.spots) {
        if (spot.theoryLink != null) continue;
        for (final tag in spot.tags) {
          if (!under.contains(tag)) continue;
          final lesson = _library.findByTags([tag]).firstOrNull;
          if (lesson == null) continue;
          spot.theoryLink = InlineTheoryLink(
            title: lesson.title,
            onTap: () => _navigator.openLessonByTag(tag),
          );
          break;
        }
      }
    }
    return packs;
  }

  /// Injects inline theory references into [spots] based on overlapping tags
  /// with available mini lessons.
  ///
  /// Returns a map of spot ids to the list of injected lesson ids.
  Future<Map<String, List<String>>> injectTheoryRefs(
    List<TrainingPackSpot> spots,
  ) async {
    final lessons = await _library.getAllLessons();
    final tagIndex = <String, List<TheoryMiniLessonNode>>{};
    for (final lesson in lessons) {
      for (final tag in lesson.tags) {
        tagIndex.putIfAbsent(tag, () => <TheoryMiniLessonNode>[]).add(lesson);
      }
    }

    final result = <String, List<String>>{};
    for (final spot in spots) {
      final refs = <String>[];
      for (final tag in spot.tags) {
        if (refs.length >= maxRefsPerSpot) break;
        final lessonsForTag = tagIndex[tag] ?? const [];
        for (final lesson in lessonsForTag) {
          if (refs.length >= maxRefsPerSpot) break;
          if (refs.contains(lesson.id)) continue;
          refs.add(lesson.id);
        }
      }
      if (refs.isNotEmpty) {
        spot.meta['theoryRefs'] = refs;
        spot.theoryRefs = refs;
      }
      result[spot.id] = refs;
    }
    return result;
  }
}
