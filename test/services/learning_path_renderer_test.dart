import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/services/mistake_booster_progress_tracker.dart';
import 'package:poker_analyzer/services/learning_path_renderer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('decorates recovered mini lesson nodes', () async {
    final tracker = MistakeBoosterProgressTracker.instance;
    await tracker.resetForTest();
    await tracker.recordProgress({'push': 0.05});
    await tracker.recordProgress({'push': 0.05});
    await tracker.recordProgress({'push': 0.05});

    final nodes = [
      TheoryMiniLessonNode(
        id: 'a',
        title: 'A',
        content: '',
        tags: const ['push'],
        nextIds: const [],
      ),
      TheoryMiniLessonNode(
        id: 'b',
        title: 'B',
        content: '',
        tags: const ['call'],
        nextIds: const [],
      ),
    ];

    final renderer = LearningPathRenderer();
    final result = await renderer.render(nodes);

    expect(result[0].recoveredFromMistake, isTrue);
    expect(result[1].recoveredFromMistake, isFalse);
  });
}
