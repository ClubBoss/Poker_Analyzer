import 'package:test/test.dart';
import 'package:poker_analyzer/ui/modules/icm_bb_packs.dart';
import 'package:poker_analyzer/services/spot_importer.dart';
import 'package:poker_analyzer/ui/session_player/models.dart';

void main() {
  test('ICM L4 BB starter pack parses correctly', () {
    final report = SpotImporter.parse(icmL4BbV1Jsonl, format: 'jsonl');
    expect(report.errors, isEmpty);
    expect(report.spots.length, greaterThanOrEqualTo(10));
    for (final spot in report.spots) {
      expect(spot.kind, SpotKind.l4_icm_bb_jam_vs_fold);
      expect(spot.pos, 'BB');
      expect(['jam', 'fold'], contains(spot.action));
      expect(spot.stack, isNotEmpty);
    }
  });
}
