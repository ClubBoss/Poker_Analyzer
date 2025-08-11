import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:poker_analyzer/services/bandit_weight_learner.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('deltas adjust impacts with exploration bonus', () async {
    final learner = BanditWeightLearner.instance;
    await learner.updateFromOutcome('u', {'A': 0.2, 'B': -0.2});

    final impactA = await learner.getImpact('u', 'A');
    final impactB = await learner.getImpact('u', 'B');
    expect(impactA > 1.0, true);
    expect(impactB < 1.0, true);

    final prefs = await SharedPreferences.getInstance();
    final a = prefs.getDouble('bandit.alpha.u.A') ?? 1.0;
    final b = prefs.getDouble('bandit.beta.u.A') ?? 1.0;
    final mean = a / (a + b);
    var baseImpact = 1.0 + 0.8 * (mean - 0.5);
    baseImpact = baseImpact.clamp(0.5, 2.0);
    expect((impactA - baseImpact).abs(), closeTo(0.05, 0.01));
  });
}
