import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/models/theory_mini_lesson_node.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/booster_cooldown_service.dart';
import 'package:poker_analyzer/services/booster_path_history_service.dart';
import 'package:poker_analyzer/services/mini_lesson_progress_tracker.dart';
import 'package:poker_analyzer/services/theory_recall_evaluator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    BoosterPathHistoryService.instance.resetForTest();
  });

  test('rank orders lessons by relevance and penalties', () async {
    final lessons = [
      const TheoryMiniLessonNode(
        id: 'l1',
        title: 'L1',
        content: '',
        tags: ['level2', 'openfold'],
        stage: 'level2',
      ),
      const TheoryMiniLessonNode(
        id: 'l2',
        title: 'L2',
        content: '',
        tags: ['level2', 'openfold'],
        stage: 'level2',
      ),
      const TheoryMiniLessonNode(
        id: 'l3',
        title: 'L3',
        content: '',
        tags: ['openfold', 'level1'],
        stage: 'level1',
      ),
    ];

    final spot = TrainingPackSpot(
      id: 's1',
      hand: HandData(),
      tags: ['level2', 'openfold'],
    );

    // mark l3 completed so it's penalized
    await MiniLessonProgressTracker.instance.markCompleted('l3');
    // mark l2 shown to trigger cooldown
    await BoosterPathHistoryService.instance.markShown('l2', 'openfold');

    final evaluator = TheoryRecallEvaluator(
      cooldown: BoosterCooldownService(cooldown: const Duration(days: 3)),
      progress: MiniLessonProgressTracker.instance,
    );

    final ranked = await evaluator.rank(lessons, spot);

    expect(ranked.first.id, 'l1');
    expect(ranked.last.id, 'l2');
  });
}
