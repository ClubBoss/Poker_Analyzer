import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/pack_run_session_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('scope key isolates cooldown state', () async {
    SharedPreferences.setMockInitialValues({});
    final k1 = PackRunSessionState.keyFor(packId: 'p1', sessionId: 's1');
    final k2 = PackRunSessionState.keyFor(packId: 'p2', sessionId: 's1');

    final s1 = await PackRunSessionState.load(k1);
    s1.tagLastShown['t'] = 5;
    await s1.save();

    final reloaded1 = await PackRunSessionState.load(k1);
    final reloaded2 = await PackRunSessionState.load(k2);

    expect(reloaded1.tagLastShown['t'], 5);
    expect(reloaded2.tagLastShown.containsKey('t'), false);
  });
}
