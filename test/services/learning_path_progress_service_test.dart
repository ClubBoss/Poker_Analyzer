import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/learning_path_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    LearningPathProgressService.instance
      ..mock = true;
  });

  test('first item available when nothing completed', () async {
    final stages = await LearningPathProgressService.instance.getCurrentStageState();
    expect(stages.first.items.first.status, LearningItemStatus.available);
    expect(stages.first.items[1].status, LearningItemStatus.locked);
  });

  test('completing first item unlocks next', () async {
    await LearningPathProgressService.instance.markCompleted('starter_pushfold_10bb');
    final stages = await LearningPathProgressService.instance.getCurrentStageState();
    expect(stages.first.items.first.status, LearningItemStatus.completed);
    expect(stages.first.items[1].status, LearningItemStatus.completed);
    expect(stages.first.items[2].status, LearningItemStatus.available);
  });
}
