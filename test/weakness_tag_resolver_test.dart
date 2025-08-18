import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/weakness_tag_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('resolveRelevantStages returns mapped stages for known tags', () {
    const resolver = WeaknessTagResolver();

    final sbStages = resolver.resolveRelevantStages('SBvsBB');
    expect(sbStages.map((e) => e.id), contains('push_fold_cash_stage'));

    final threeBetStages = resolver.resolveRelevantStages('3betPot');
    expect(
      threeBetStages.map((e) => e.id),
      contains('3bet_push_sb_vs_btn_stage'),
    );

    final openStages = resolver.resolveRelevantStages('openfold');
    expect(openStages.map((e) => e.id), contains('open_fold_lj_mtt_stage'));
  });

  test('resolveRelevantStages returns empty list for unknown tag', () {
    const resolver = WeaknessTagResolver();
    final result = resolver.resolveRelevantStages('unknown');
    expect(result, isEmpty);
  });
}
