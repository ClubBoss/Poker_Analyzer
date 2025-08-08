import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_link_config_service.dart';
import 'package:poker_analyzer/services/theory_link_policy_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('perSessionCap=1 blocks second inject', () async {
    SharedPreferences.setMockInitialValues({
      'theory.cap.session': 1,
      'theory.cap.day': 99,
      'theory.tag.cooldownHours': 24,
    });
    final prefs = await SharedPreferences.getInstance();
    await TheoryLinkConfigService.instance.reload();
    final policy = TheoryLinkPolicyEngine(prefs: prefs);
    final allowed1 = await policy.canInject('u1', {'t'});
    expect(allowed1, true);
    await policy.onInjected('u1', {'t'});
    final allowed2 = await policy.canInject('u1', {'t'});
    expect(allowed2, false);
  });

  test('perDayCap=1 blocks second inject same day', () async {
    SharedPreferences.setMockInitialValues({
      'theory.cap.session': 99,
      'theory.cap.day': 1,
      'theory.tag.cooldownHours': 24,
    });
    final prefs = await SharedPreferences.getInstance();
    await TheoryLinkConfigService.instance.reload();
    final policy = TheoryLinkPolicyEngine(prefs: prefs);
    expect(await policy.canInject('u1', {'a'}), true);
    await policy.onInjected('u1', {'a'});
    expect(await policy.canInject('u1', {'b'}), false);
  });

  test('perTagCooldown blocks same tag', () async {
    SharedPreferences.setMockInitialValues({
      'theory.cap.session': 99,
      'theory.cap.day': 99,
      'theory.tag.cooldownHours': 24,
    });
    final prefs = await SharedPreferences.getInstance();
    await TheoryLinkConfigService.instance.reload();
    final policy = TheoryLinkPolicyEngine(prefs: prefs);
    expect(await policy.canInject('u1', {'x'}), true);
    await policy.onInjected('u1', {'x'});
    expect(await policy.canInject('u1', {'x'}), false);
  });
}
