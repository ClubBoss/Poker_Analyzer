import 'package:test/test.dart';
import 'package:poker_analyzer/ui/modules/cash_packs.dart';
import 'package:poker_analyzer/services/spot_importer.dart';
import 'package:poker_analyzer/ui/session_player/models.dart';

void main() {
  test('cash L3 starter pack parses correctly', () {
    final report = SpotImporter.parse(cashL3V1Jsonl, format: 'jsonl');
    expect(report.errors, isEmpty);
    expect(report.spots.length, greaterThanOrEqualTo(10));
    const allowedKinds = {
      SpotKind.l3_flop_jam_vs_raise,
      SpotKind.l3_turn_jam_vs_raise,
      SpotKind.l3_river_jam_vs_raise,
    };
    for (final spot in report.spots) {
      expect(allowedKinds, contains(spot.kind));
      expect(['jam', 'fold'], contains(spot.action));
      expect(spot.stack, isNotEmpty);
    }
  });
}
