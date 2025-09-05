import 'package:test/test.dart';

import 'package:poker_analyzer/infra/kpi_gate.dart';

void main() {
  setUp(() {
    // Reset override and targets before each test.
    kEnableKPIOverride = kEnableKPI;
    kModuleKPI.clear();
  });

  test('disabled flag -> always true', () {
    kEnableKPIOverride = false; // ensure disabled
    expect(
      meetsKPI(moduleId: '', correct: 0, total: 0, avgDecisionMs: 999999),
      isTrue,
    );
    expect(
      meetsKPI(moduleId: 'x', correct: 1, total: 100, avgDecisionMs: 60000),
      isTrue,
    );
  });

  test('enabled with default target (80%, 25s)', () {
    kEnableKPIOverride = true;
    // Exactly on boundaries
    expect(
      meetsKPI(moduleId: 'any', correct: 8, total: 10, avgDecisionMs: 25000),
      isTrue,
    );
    // Below accuracy
    expect(
      meetsKPI(moduleId: 'any', correct: 7, total: 10, avgDecisionMs: 24000),
      isFalse,
    );
    // Above time threshold
    expect(
      meetsKPI(moduleId: 'any', correct: 8, total: 10, avgDecisionMs: 25001),
      isFalse,
    );
  });

  test('custom module target is stricter', () {
    kEnableKPIOverride = true;
    kModuleKPI['cash_threebet_pots'] = KPITarget(85, 20000);
    // Meets exactly
    expect(
      meetsKPI(
          moduleId: 'cash_threebet_pots',
          correct: 17,
          total: 20,
          avgDecisionMs: 20000),
      isTrue,
    );
    // Miss accuracy
    expect(
      meetsKPI(
          moduleId: 'cash_threebet_pots',
          correct: 16,
          total: 20,
          avgDecisionMs: 18000),
      isFalse,
    );
    // Miss time
    expect(
      meetsKPI(
          moduleId: 'cash_threebet_pots',
          correct: 17,
          total: 20,
          avgDecisionMs: 20001),
      isFalse,
    );
  });
}

