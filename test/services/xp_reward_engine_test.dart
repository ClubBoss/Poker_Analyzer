import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/xp_reward_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('addXp accumulates total', () async {
    SharedPreferences.setMockInitialValues({});
    final engine = XPRewardEngine.instance;
    await engine.addXp(10);
    await engine.addXp(5);
    final total = await engine.getTotalXp();
    expect(total, 15);
  });
}
