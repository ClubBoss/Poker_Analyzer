import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/training_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('getSubStageProgress caches per stage', () async {
    SharedPreferences.setMockInitialValues({
      'tpl_prog_starter_pushfold_10bb': 0,
    });
    final service = TrainingProgressService.instance;
    service.subStageProgress.clear();
    final first = await service.getSubStageProgress(
      'stage1',
      'starter_pushfold_10bb',
    );
    expect(service.subStageProgress['stage1']?['starter_pushfold_10bb'], first);
    expect(first, greaterThan(0));
    SharedPreferences.setMockInitialValues({
      'tpl_prog_starter_pushfold_10bb': 5,
    });
    final second = await service.getSubStageProgress(
      'stage1',
      'starter_pushfold_10bb',
    );
    expect(second, first);
  });
}
