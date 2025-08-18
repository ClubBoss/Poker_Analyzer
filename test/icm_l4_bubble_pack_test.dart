import 'package:test/test.dart';
import 'package:poker_analyzer/ui/modules/icm_bubble_packs.dart';
import 'package:poker_analyzer/services/spot_importer.dart';
import 'package:poker_analyzer/ui/session_player/models.dart';

void main() {
  test('ICM L4 Bubble starter pack parses correctly', () {
    final report = SpotImporter.parse(icmL4BubbleV1Jsonl, format: 'jsonl');
    expect(report.errors, isEmpty);
    expect(report.spots.length, greaterThanOrEqualTo(10));
    for (final spot in report.spots) {
      expect(spot.kind, SpotKind.l4_icm_bubble_jam_vs_fold);
      expect(['SB', 'BB'], contains(spot.pos));
      expect(['jam', 'fold'], contains(spot.action));
      expect(spot.stack, isNotEmpty);
    }
  });
}

