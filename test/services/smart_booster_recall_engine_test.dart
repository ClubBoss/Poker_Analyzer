import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:poker_analyzer/services/smart_booster_recall_engine.dart';
import 'package:poker_analyzer/services/booster_context_evaluator.dart';

class _FakeEvaluator extends BoosterContextEvaluator {
  final Set<String> relevant;
  const _FakeEvaluator(this.relevant);

  @override
  Future<bool> isRelevant(String type) async => relevant.contains(type);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SmartBoosterRecallEngine.instance.resetForTest();
  });

  test('recalls types after cooldown when relevant', () async {
    final engine = SmartBoosterRecallEngine(
      evaluator: const _FakeEvaluator({'a'}),
    );
    final old = DateTime.now().subtract(const Duration(hours: 50));
    await engine.recordDismissed('a', timestamp: old);
    await engine.recordDismissed('b', timestamp: old);
    final types = await engine.getRecallableTypes(DateTime.now());
    expect(types, ['a']);
  });

  test('ignores types before cooldown', () async {
    final engine = SmartBoosterRecallEngine(
      evaluator: const _FakeEvaluator({'a'}),
    );
    final recent = DateTime.now().subtract(const Duration(hours: 10));
    await engine.recordDismissed('a', timestamp: recent);
    final types = await engine.getRecallableTypes(DateTime.now());
    expect(types, isEmpty);
  });
}
