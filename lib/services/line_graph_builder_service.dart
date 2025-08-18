import '../models/theory_mini_lesson_node.dart';
import '../models/v2/training_pack_spot.dart';
import 'line_graph_engine.dart';

/// Builds a [LineGraphEngine] from theory lessons, training spots and lines.
class LineGraphBuilderService {
  final LineGraphEngine _engine;

  LineGraphBuilderService({LineGraphEngine? engine})
    : _engine = engine ?? LineGraphEngine();

  LineGraphEngine build({
    List<TheoryMiniLessonNode> lessons = const [],
    List<TrainingPackSpot> spots = const [],
    List<List<String>> lines = const [],
  }) {
    for (final line in lines) {
      _engine.addLine(line);
    }
    for (final l in lessons) {
      _engine.linkLesson(l);
    }
    for (final s in spots) {
      _engine.linkSpot(s);
    }
    return _engine;
  }
}
