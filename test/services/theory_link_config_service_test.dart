import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/theory_link_config_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads values from prefs', () async {
    SharedPreferences.setMockInitialValues({
      'theory.maxPerModule': 5,
      'theory.maxPerPack': 4,
      'theory.maxPerSpot': 3,
      'theory.noveltyRecentHours': 10,
      'theory.noveltyMinOverlap': 0.7,
      'theory.weight.tag': 0.1,
      'theory.weight.errorRate': 0.6,
      'theory.weight.decay': 0.3,
      'theory.ablation': true,
      'theory.cap.session': 9,
      'theory.cap.day': 20,
      'theory.tag.cooldownHours': 12,
    });
    await TheoryLinkConfigService.instance.reload();
    final cfg = TheoryLinkConfigService.instance.value;
    expect(cfg.maxPerModule, 5);
    expect(cfg.maxPerPack, 4);
    expect(cfg.maxPerSpot, 3);
    expect(cfg.noveltyRecent, const Duration(hours: 10));
    expect(cfg.noveltyMinOverlap, 0.7);
    expect(cfg.wTag, 0.1);
    expect(cfg.wErr, 0.6);
    expect(cfg.wDecay, 0.3);
    expect(cfg.ablationEnabled, true);
    expect(cfg.perSessionCap, 9);
    expect(cfg.perDayCap, 20);
    expect(cfg.perTagCooldownHours, 12);
  });
}
