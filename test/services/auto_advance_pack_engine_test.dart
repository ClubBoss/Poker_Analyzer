import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/auto_advance_pack_engine.dart';
import 'package:poker_analyzer/services/learning_path_progress_service.dart';
import 'package:poker_analyzer/models/v2/training_pack_template_v2.dart';
import 'package:poker_analyzer/core/training/engine/training_type_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    LearningPathProgressService.instance.mock = true;
    await LearningPathProgressService.instance.resetProgress();
    AutoAdvancePackEngine.instance
      ..mock = true
      ..resetMock()
      ..registerMockTemplate(
        TrainingPackTemplateV2(
          id: 'starter_pushfold_10bb',
          name: 'A',
          trainingType: TrainingType.pushFold,
        ),
      )
      ..registerMockTemplate(
        TrainingPackTemplateV2(
          id: 'starter_pushfold_15bb',
          name: 'B',
          trainingType: TrainingType.pushFold,
        ),
      );
  });

  test('returns first pack when none completed', () async {
    final tpl = await AutoAdvancePackEngine.instance.getNextRecommendedPack();
    expect(tpl?.id, 'starter_pushfold_10bb');
  });

  test('returns next pack after completion', () async {
    await LearningPathProgressService.instance.markCompleted(
      'starter_pushfold_10bb',
    );
    final tpl = await AutoAdvancePackEngine.instance.getNextRecommendedPack();
    expect(tpl?.id, 'starter_pushfold_15bb');
  });
}
