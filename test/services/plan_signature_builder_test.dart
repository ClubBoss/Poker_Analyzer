import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/plan_signature_builder.dart';
import 'package:poker_analyzer/services/adaptive_training_planner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stable hash and sensitivity to inputs', () async {
    final builder = PlanSignatureBuilder();
    final plan = AdaptivePlan(
      clusters: const [],
      estMins: 10,
      tagWeights: const {'a': 1.0, 'b': 2.0},
      mix: const {'theory': 1, 'booster': 1, 'assessment': 0},
    );
    final sig1 = await builder.build(
      userId: 'u1',
      plan: plan,
      audience: 'regular',
      format: 'standard',
      budgetMinutes: 30,
    );
    final sig2 = await builder.build(
      userId: 'u1',
      plan: plan,
      audience: 'regular',
      format: 'standard',
      budgetMinutes: 30,
    );
    expect(sig1, sig2);

    final plan2 = AdaptivePlan(
      clusters: const [],
      estMins: 10,
      tagWeights: const {'a': 1.0, 'b': 2.0},
      mix: const {'theory': 2, 'booster': 0, 'assessment': 0},
    );
    final sig3 = await builder.build(
      userId: 'u1',
      plan: plan2,
      audience: 'regular',
      format: 'standard',
      budgetMinutes: 30,
    );
    expect(sig1, isNot(sig3));

    final sig4 = await builder.build(
      userId: 'u1',
      plan: plan,
      audience: 'novice',
      format: 'standard',
      budgetMinutes: 30,
    );
    expect(sig1, isNot(sig4));
  });
}
