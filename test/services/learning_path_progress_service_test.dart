import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/learning_path_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LearningPathProgressService.instance.mock = true;
    await LearningPathProgressService.instance.resetProgress();
    await LearningPathProgressService.instance.resetCustomPath();
  });

  test('first item available when nothing completed', () async {
    final stages =
        await LearningPathProgressService.instance.getCurrentStageState();
    expect(stages.first.items.first.status, LearningItemStatus.available);
    expect(stages.first.items[1].status, LearningItemStatus.locked);
  });

  test('next stage locked until previous completed', () async {
    final stages =
        await LearningPathProgressService.instance.getCurrentStageState();
    expect(stages[1].items.first.status, LearningItemStatus.locked);
  });

  test('completing first item unlocks next', () async {
    await LearningPathProgressService.instance.markCompleted(
      'starter_pushfold_10bb',
    );
    final stages =
        await LearningPathProgressService.instance.getCurrentStageState();
    expect(stages.first.items.first.status, LearningItemStatus.completed);
    expect(stages.first.items[1].status, LearningItemStatus.completed);
    expect(stages.first.items[2].status, LearningItemStatus.available);
  });

  test('completing first stage unlocks second stage', () async {
    await LearningPathProgressService.instance.markCompleted(
      'starter_pushfold_10bb',
    );
    await LearningPathProgressService.instance.markCompleted(
      'starter_pushfold_15bb',
    );
    final stages =
        await LearningPathProgressService.instance.getCurrentStageState();
    expect(stages[1].items.first.status, isNot(LearningItemStatus.locked));
  });

  test('isAllStagesCompleted works correctly', () async {
    var done =
        await LearningPathProgressService.instance.isAllStagesCompleted();
    expect(done, isFalse);

    await LearningPathProgressService.instance.markCompleted(
      'starter_pushfold_10bb',
    );
    await LearningPathProgressService.instance.markCompleted(
      'starter_pushfold_15bb',
    );
    await LearningPathProgressService.instance.markCompleted(
      'starter_pushfold_12bb',
    );
    await LearningPathProgressService.instance.markCompleted(
      'starter_pushfold_20bb',
    );

    done = await LearningPathProgressService.instance.isAllStagesCompleted();
    expect(done, isTrue);
  });

  test('intro flag persists', () async {
    var seen = await LearningPathProgressService.instance.hasSeenIntro();
    expect(seen, isFalse);
    await LearningPathProgressService.instance.markIntroSeen();
    seen = await LearningPathProgressService.instance.hasSeenIntro();
    expect(seen, isTrue);
    await LearningPathProgressService.instance.resetIntroSeen();
    seen = await LearningPathProgressService.instance.hasSeenIntro();
    expect(seen, isFalse);
  });

  test('resetStage clears progress', () async {
    await LearningPathProgressService.instance.markCompleted(
      'starter_pushfold_10bb',
    );
    await LearningPathProgressService.instance.resetStage('Beginner');
    final stages =
        await LearningPathProgressService.instance.getCurrentStageState();
    expect(stages.first.items.first.status, LearningItemStatus.available);
    expect(stages.first.items[1].status, LearningItemStatus.locked);
  });

  test('custom path flag persists', () async {
    var started =
        await LearningPathProgressService.instance.isCustomPathStarted();
    expect(started, isFalse);
    await LearningPathProgressService.instance.markCustomPathStarted();
    started = await LearningPathProgressService.instance.isCustomPathStarted();
    expect(started, isTrue);
  });

  test('custom path completion flag persists', () async {
    var done =
        await LearningPathProgressService.instance.isCustomPathCompleted();
    expect(done, isFalse);
    await LearningPathProgressService.instance.markCustomPathCompleted();
    done = await LearningPathProgressService.instance.isCustomPathCompleted();
    expect(done, isTrue);
  });
}
