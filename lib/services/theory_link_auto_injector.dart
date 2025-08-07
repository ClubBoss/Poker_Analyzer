import '../models/theory_mini_lesson_node.dart';
import '../models/v2/training_pack_spot.dart';

/// Injects references to [TheoryMiniLessonNode]s into [TrainingPackSpot]s based
/// on overlapping tags.
class TheoryLinkAutoInjector {
  const TheoryLinkAutoInjector({this.maxLinks = 2, this.strict = false});

  /// Maximum number of lesson references to inject per spot.
  final int maxLinks;

  /// When true, only inject when the lesson's tags exactly match the spot's
  /// tag set.
  final bool strict;

  /// Injects relevant theory links into [spots] from [lessons].
  void injectAll(
    List<TrainingPackSpot> spots,
    List<TheoryMiniLessonNode> lessons,
  ) {
    for (final spot in spots) {
      inject(spot, lessons);
    }
  }

  /// Injects lesson references into a single [spot].
  TrainingPackSpot inject(
    TrainingPackSpot spot,
    List<TheoryMiniLessonNode> lessons,
  ) {
    final refs = <String>[];
    final spotTags = spot.tags.toSet();
    for (final lesson in lessons) {
      if (refs.length >= maxLinks) break;
      final lessonTags = lesson.tags.toSet();
      final matches = strict
          ? spotTags.length == lessonTags.length &&
                spotTags.containsAll(lessonTags)
          : spotTags.intersection(lessonTags).isNotEmpty;
      if (matches) {
        refs.add(lesson.id);
      }
    }
    spot.theoryRefs = refs;
    if (refs.isNotEmpty) {
      // Simple logging for audit purposes.
      // ignore: avoid_print
      print('TheoryLinkAutoInjector: ${spot.id} -> $refs');
    }
    return spot;
  }
}
