import '../../models/theory_mini_lesson_node.dart';
import '../../models/v2/training_pack_template_v2.dart';
import '../../services/mini_lesson_library_service.dart';

/// Links river jam decision spots to relevant theory mini lessons.
class PostflopJamDecisionTheoryLinker {
  PostflopJamDecisionTheoryLinker({MiniLessonLibraryService? library})
    : _library = library ?? MiniLessonLibraryService.instance;

  final MiniLessonLibraryService _library;

  /// Injects `theoryRef` links into qualifying packs.
  ///
  /// Packs are considered when their `meta.topic` equals `river jam` or
  /// contain the tag `jamDecision`. For the first [TheoryMiniLessonNode]
  /// that has all tags `river`, `jam` and `decision`, each spot's `meta`
  /// map receives a `theoryRef` entry with the lesson's id and title.
  Future<void> link(List<TrainingPackTemplateV2> packs) async {
    if (packs.isEmpty) return;
    await _library.loadAll();

    const required = ['river', 'jam', 'decision'];
    final candidates = _library.findByTags(required);
    final lesson = candidates.firstWhere(
      (l) => required.every((t) => l.tags.contains(t)),
      orElse: () => null,
    );

    for (final pack in packs) {
      final topic = pack.meta['topic']?.toString().toLowerCase();
      final hasTag = pack.tags
          .map((t) => t.toLowerCase())
          .contains('jamdecision');
      if (topic != 'river jam' && !hasTag) continue;

      for (final spot in pack.spots) {
        if (spot.meta.containsKey('theoryRef')) continue;
        spot.meta['theoryRef'] = {'lessonId': lesson.id, 'title': lesson.title};
      }
    }
  }
}
