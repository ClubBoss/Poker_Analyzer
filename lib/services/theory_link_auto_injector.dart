import '../models/card_model.dart';
import '../models/theory_mini_lesson_node.dart';
import '../models/v2/training_pack_spot.dart';
import 'board_texture_classifier.dart';
import 'mini_lesson_library_service.dart';

/// Injects inline theory references into [TrainingPackSpot]s based on shared
/// tags and board texture.
class TheoryLinkAutoInjector {
  TheoryLinkAutoInjector({
    this.maxLinks = 3,
    MiniLessonLibraryService? library,
    BoardTextureClassifier? boardClassifier,
  })  : library = library ?? MiniLessonLibraryService.instance,
        boardClassifier = boardClassifier ?? const BoardTextureClassifier();

  /// Maximum number of lesson ids to attach to each spot.
  final int maxLinks;

  /// Source of theory mini-lessons.
  final MiniLessonLibraryService library;

  /// Classifier used to extract board texture tags.
  final BoardTextureClassifier boardClassifier;

  /// Scans [spots] and injects matching theory lesson ids into
  /// `spot.meta['linkedTheoryLessonIds']`.
  Future<void> injectAll(List<TrainingPackSpot> spots) async {
    final lessons = await library.getAllLessons();
    for (final spot in spots) {
      _inject(spot, lessons);
    }
  }

  void _inject(TrainingPackSpot spot, List<TheoryMiniLessonNode> lessons) {
    final boardTags = _boardTags(spot);
    final spotTags = {...spot.tags, ...boardTags};
    final ids = <String>[];
    for (final lesson in lessons) {
      if (ids.length >= maxLinks) break;
      final lt = lesson.tags.toSet();
      if (spotTags.intersection(lt).isNotEmpty) {
        ids.add(lesson.id);
      }
    }
    if (ids.isNotEmpty) {
      spot.meta['linkedTheoryLessonIds'] = ids;
      // ignore: avoid_print
      print('TheoryLinkAutoInjector: ${spot.id} -> $ids');
    }
  }

  Set<String> _boardTags(TrainingPackSpot spot) {
    final cards = <CardModel>[];
    for (final c in spot.board) {
      if (c.length >= 2) {
        cards.add(CardModel(rank: c[0], suit: c[1]));
      }
    }
    return boardClassifier.classifyCards(cards);
  }
}

