import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/learning_path_player_progress_service.dart';
import 'package:poker_analyzer/models/learning_path_player_progress.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('round trip and corrupt fallback', () async {
    SharedPreferences.setMockInitialValues({});
    final service = LearningPathProgressService.instance;
    final progress = LearningPathProgress(stages: {
      's': const StageProgress(handsPlayed: 1),
    }, currentStageId: 's');
    await service.save('p', progress);
    final loaded = await service.load('p');
    expect(loaded.stages['s']?.handsPlayed, 1);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('learning.path.progress.p', '{bad json');
    final empty = await service.load('p');
    expect(empty.stages.isEmpty, true);
    expect(prefs.getString('learning.path.progress.p.bak'), '{bad json');
  });
}

