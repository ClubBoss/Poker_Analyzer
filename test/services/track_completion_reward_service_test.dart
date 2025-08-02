import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/track_completion_reward_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('grants reward only once', () async {
    final svc = TrackCompletionRewardService.instance;
    final first = await svc.grantReward('T');
    expect(first, isTrue);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('reward_granted_T'), isTrue);
    final second = await svc.grantReward('T');
    expect(second, isFalse);
  });
}
