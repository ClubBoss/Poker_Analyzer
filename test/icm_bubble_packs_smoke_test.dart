import 'package:test/test.dart';
import 'package:poker_analyzer/ui/modules/icm_bubble_packs.dart';
import 'package:poker_analyzer/ui/session_player/models.dart';
import 'package:poker_analyzer/ui/session_player/spot_specs.dart';

void main() {
  test('ICM Bubble pack loads and has jam/fold wiring', () {
    final spots = loadIcmL4BubbleV1();
    expect(spots, isNotEmpty);
    expect(spots.map((s) => s.kind).toSet(), {
      SpotKind.l4_icm_bubble_jam_vs_fold,
    });
    expect(actionsMap[SpotKind.l4_icm_bubble_jam_vs_fold], ['jam', 'fold']);
    expect(
      subtitlePrefix[SpotKind.l4_icm_bubble_jam_vs_fold],
      'ICM Bubble Jam vs Fold • ',
    );
  });

  test('ICM Bubble pack has no duplicate jam keys', () {
    final spots = loadIcmL4BubbleV1();
    final keys = spots.map(jamDedupKey).toList();
    expect(keys.toSet().length, keys.length);
  });
}
