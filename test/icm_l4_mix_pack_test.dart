import 'package:test/test.dart';
import 'package:poker_analyzer/ui/modules/icm_mix_packs.dart';
import 'package:poker_analyzer/services/spot_importer.dart';
import 'package:poker_analyzer/ui/session_player/models.dart';

void main() {
  test('ICM L4 Mix starter pack parses correctly', () {
    final report = SpotImporter.parse(icmL4MixV1Jsonl, format: 'jsonl');
    expect(report.errors, isEmpty);
    expect(report.spots.length, greaterThanOrEqualTo(20));
    for (final spot in report.spots) {
      expect([
        'l4_icm_sb_jam_vs_fold',
        'l4_icm_bb_jam_vs_fold',
      ], contains(spot.kind.name));
      expect(['SB', 'BB'], contains(spot.pos));
      expect(['jam', 'fold'], contains(spot.action));
      expect(spot.stack, isNotEmpty);
    }
  });
}
