import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/learning_path_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LearningPathProgressService.instance.mock = true;
    await LearningPathProgressService.instance.resetProgress();
  });

  test('level indexes sequential', () async {
    final stages =
        await LearningPathProgressService.instance.getCurrentStageState();
    for (var i = 0; i < stages.length; i++) {
      expect(stages[i].levelIndex, i + 1);
    }
  });
}
