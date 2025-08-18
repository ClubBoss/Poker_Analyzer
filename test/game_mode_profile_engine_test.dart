import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/game_mode_profile_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('defaults to cashOnline when no value stored', () async {
    SharedPreferences.setMockInitialValues({});
    await GameModeProfileEngine.instance.load();
    expect(
      GameModeProfileEngine.instance.getActiveProfile(),
      GameModeProfile.cashOnline,
    );
  });

  test('setActiveProfile stores and returns value', () async {
    SharedPreferences.setMockInitialValues({});
    await GameModeProfileEngine.instance.load();
    await GameModeProfileEngine.instance.setActiveProfile(
      GameModeProfile.mttLive,
    );

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getInt('active_game_mode_profile'),
      GameModeProfile.mttLive.index,
    );
    expect(
      GameModeProfileEngine.instance.getActiveProfile(),
      GameModeProfile.mttLive,
    );
  });
}
