import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/unlock_condition.dart';
import 'package:poker_analyzer/services/unlock_condition_evaluator.dart';

void main() {
  const eval = UnlockConditionEvaluator();

  test('unlocked when no condition', () {
    expect(eval.isUnlocked(null, const {}, const {}), isTrue);
  });

  test('locked when dependency incomplete', () {
    const cond = UnlockCondition(dependsOn: 'a', minAccuracy: 70);
    expect(eval.isUnlocked(cond, {'a': 0.5}, {'a': 80}), isFalse);
  });

  test('locked when accuracy low', () {
    const cond = UnlockCondition(dependsOn: 'a', minAccuracy: 90);
    expect(eval.isUnlocked(cond, {'a': 1.0}, {'a': 80}), isFalse);
  });

  test('unlocked when requirements met', () {
    const cond = UnlockCondition(dependsOn: 'a', minAccuracy: 80);
    expect(eval.isUnlocked(cond, {'a': 1.0}, {'a': 80}), isTrue);
  });
}
