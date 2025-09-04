import 'package:test/test.dart';
import 'package:poker_analyzer/curriculum/unit_id_utils.dart';

void main() {
  test('practiceIdsFor builds per-module practice IDs', () {
    expect(practiceIdsFor('core_rules_and_setup'), [
      'core_rules_and_setup_l1',
      'core_rules_and_setup_l2',
    ]);
  });

  test('bridgeId formats with zero-padded indices', () {
    expect(bridgeId(branch: 'core', aIdx: 2, bIdx: 3), 'bridge_core_02_03');
  });

  test('checkpointId formats with zero-padded unit', () {
    expect(checkpointId(branch: 'cash', unit: 3), 'checkpoint_cash_unit_03');
  });

  test('bossId formats branch boss', () {
    expect(bossId('mtt'), 'boss_mtt');
  });
}
