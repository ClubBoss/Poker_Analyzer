import 'package:test/test.dart';
import 'package:poker_analyzer/services/auto_deduplication_engine.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';

void main() {
  test('deduplicates spots by fingerprint', () {
    final spot1 = TrainingPackSpot(
      id: 'a',
      hand: HandData(position: HeroPosition.sb),
    );
    final spot2 = TrainingPackSpot(
      id: 'b',
      hand: HandData(position: HeroPosition.sb),
    );
    final unique = TrainingPackSpot(
      id: 'c',
      hand: HandData(position: HeroPosition.bb),
    );
    final pack = TrainingPackModel(
      id: 'p1',
      title: 'test',
      spots: [spot1, spot2, unique],
    );

    final engine = AutoDeduplicationEngine();
    final result = engine.deduplicate(pack);

    expect(result.spots.length, 2);
    expect(result.spots.where((s) => s.id == 'a').length, 1);
    expect(result.spots.where((s) => s.id == 'b').isEmpty, isTrue);
    expect(result.spots.where((s) => s.id == 'c').length, 1);
  });
}
