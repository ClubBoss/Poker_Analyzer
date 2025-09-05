import 'package:test/test.dart';

import 'package:poker_analyzer/infra/kpi_fields_pure.dart';
import 'package:poker_analyzer/infra/kpi_gate.dart';

void main() {
  setUp(() {
    kModuleKPI.clear();
  });

  test('disabled: fields present; kpi_met omitted', () {
    final m = kpiFields(
      moduleId: null,
      total: null,
      correct: null,
      avgMs: null,
      enabled: false,
    );
    expect(m.containsKey('session_module_id'), isTrue);
    expect(m.containsKey('session_total'), isTrue);
    expect(m.containsKey('session_correct'), isTrue);
    expect(m.containsKey('session_avg_decision_ms'), isTrue);
    expect(m['kpi_enabled'], isFalse);
    expect(m.containsKey('kpi_met'), isFalse);
  });

  test('enabled + default target passes on 90% / 20s', () {
    final m = kpiFields(
      moduleId: 'cash_threebet_pots',
      total: 20,
      correct: 18,
      avgMs: 20000,
      enabled: true,
    );
    expect(m['kpi_enabled'], isTrue);
    expect(m['kpi_target_accuracy'], 80);
    expect(m['kpi_target_time_ms'], 25000);
    expect(m['kpi_met'], isTrue);
  });

  test('boundaries fail: 79% or 26s', () {
    final a = kpiFields(
      moduleId: 'any',
      total: 100,
      correct: 79,
      avgMs: 20000,
      enabled: true,
    );
    expect(a['kpi_met'], isFalse);

    final b = kpiFields(
      moduleId: 'any',
      total: 100,
      correct: 80,
      avgMs: 26000,
      enabled: true,
    );
    expect(b['kpi_met'], isFalse);
  });
}
