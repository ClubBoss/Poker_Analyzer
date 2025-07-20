import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/training_path_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('progress updates correctly', () async {
    final service = TrainingPathProgressService.instance;
    var progress = await service.getProgressInStage('beginner');
    expect(progress, 0.0);

    await service.markCompleted('starter_pushfold_10bb');
    progress = await service.getProgressInStage('beginner');
    expect(progress, closeTo(0.5, 0.001));

    final completed = await service.getCompletedPacksInStage('beginner');
    expect(completed, ['starter_pushfold_10bb']);
  });
}
