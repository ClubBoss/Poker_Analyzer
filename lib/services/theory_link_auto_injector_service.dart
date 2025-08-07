import 'package:collection/collection.dart';

import '../models/skill_tag_coverage_report.dart';
import '../models/training_pack_model.dart';
import '../models/v2/training_pack_spot.dart';
import 'mini_lesson_library_service.dart';
import 'theory_mini_lesson_navigator.dart';
import 'inline_theory_linker.dart';

/// Injects [InlineTheoryLink]s into [TrainingPackSpot]s based on
/// underrepresented skill tags.
class TheoryLinkAutoInjectorService {
  TheoryLinkAutoInjectorService({
    MiniLessonLibraryService? library,
    TheoryMiniLessonNavigator? navigator,
  })  : _library = library ?? MiniLessonLibraryService.instance,
        _navigator = navigator ?? TheoryMiniLessonNavigator.instance;

  final MiniLessonLibraryService _library;
  final TheoryMiniLessonNavigator _navigator;

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
}
