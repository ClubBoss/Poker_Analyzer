import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/learning_path_graph_orchestrator.dart';
import 'package:poker_analyzer/services/game_mode_profile_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loadGraph loads file for active profile', () async {
    SharedPreferences.setMockInitialValues({});
    await GameModeProfileEngine.instance.load();
    await GameModeProfileEngine.instance.setActiveProfile(
      GameModeProfile.cashOnline,
    );

    final orchestrator = LearningPathGraphOrchestrator();
    final nodes = await orchestrator.loadGraph();
    expect(nodes, isNotEmpty);
    expect(nodes.first.id, 'start');
  });
}
