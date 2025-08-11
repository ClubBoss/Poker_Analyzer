import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/models/learning_path_player_progress.dart';
import 'package:poker_analyzer/services/learning_path_player_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('save/load round trip', () async {
    final service = LearningPathProgressService.instance;
    final progress = LearningPathProgress(
      stages: {
        's1': StageProgress(
          attempts: 2,
          handsPlayed: 10,
          correct: 7,
          accuracy: 0.7,
        ),
      },
      currentStageId: 's1',
    );
    await service.save('path1', progress);
    final loaded = await service.load('path1');
    expect(loaded.currentStageId, 's1');
    final stage = loaded.stages['s1'];
    expect(stage, isNotNull);
    expect(stage!.attempts, 2);
    expect(stage.accuracy, closeTo(0.7, 0.0001));
  });

  test('reset clears progress', () async {
    final service = LearningPathProgressService.instance;
    await service.save('p', LearningPathProgress(currentStageId: 'a'));
    await service.reset('p');
    final loaded = await service.load('p');
    expect(loaded.stages, isEmpty);
    expect(loaded.currentStageId, isNull);
  });

  test('recordHand updates accuracy', () {
    var stage = const StageProgress();
    stage = stage.recordHand(correct: true);
    stage = stage.recordHand(correct: false);
    expect(stage.handsPlayed, 2);
    expect(stage.correct, 1);
    expect(stage.accuracy, closeTo(0.5, 0.0001));
  });
}
