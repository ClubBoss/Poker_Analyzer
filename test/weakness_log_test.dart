import 'package:test/test.dart';

import 'package:poker_analyzer/infra/weakness_log.dart';
import 'package:poker_analyzer/ui/session_player/models.dart';

void main() {
  setUp(() {
    kEnableWeaknessLogOverride = kEnableWeaknessLog;
    weaknessLog.counts.clear();
  });

  test('flag false: records ignored', () {
    kEnableWeaknessLogOverride = false;
    weaknessLog.record('jam_vs_');
    weaknessLog.record('misc');
    expect(weaknessLog.counts, isEmpty);
  });

  test('flag true: counts top key', () {
    kEnableWeaknessLogOverride = true;
    weaknessLog.record('jam_vs_');
    weaknessLog.record('jam_vs_');
    weaknessLog.record('jam_vs_');
    weaknessLog.record('misc');
    expect(weaknessLog.counts['jam_vs_'], equals(3));
    // Find top key
    final top = weaknessLog.counts.entries.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    expect(top.key, equals('jam_vs_'));
  });

  test('familyFor mapping samples', () {
    expect(familyFor(SpotKind.l3_flop_jam_vs_raise), equals('jam_vs_'));
    expect(familyFor(SpotKind.l3_river_jam_vs_bet), equals('jam_vs_'));
    expect(familyFor(SpotKind.l3_postflop_jam), equals('misc'));
  });
}
