import 'package:test/test.dart';
import 'package:poker_analyzer/services/auto_deduplication_engine.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';

void main() {
  test('deduplicates spots by fingerprint', () {
    final spot1 = TrainingPackSpot(
      id: 'a',
      hand: HandData(heroCards: 'Ah As', position: HeroPosition.sb),
      villainAction: 'fold',
    );
    final spot2 = TrainingPackSpot(
      id: 'b',
      hand: HandData(heroCards: 'As Ah', position: HeroPosition.sb),
      villainAction: 'fold',
    );
    final unique = TrainingPackSpot(
      id: 'c',
      hand: HandData(heroCards: 'Kd Kh', position: HeroPosition.bb),
      villainAction: 'call',
    );

    final engine = AutoDeduplicationEngine();
    final result = engine.deduplicate([spot1, spot2, unique]);

    expect(result.length, 2);
    expect(result.where((s) => s.id == 'a').length, 1);
    expect(result.where((s) => s.id == 'b').isEmpty, isTrue);
    expect(result.where((s) => s.id == 'c').length, 1);
  });

  test('keeps highest weight when requested', () {
    final spot1 = TrainingPackSpot(
      id: 'a',
      hand: HandData(heroCards: 'Ah As', position: HeroPosition.sb),
      villainAction: 'fold',
      meta: {'weight': 1},
    );
    final spot2 = TrainingPackSpot(
      id: 'b',
      hand: HandData(heroCards: 'Ah As', position: HeroPosition.sb),
      villainAction: 'fold',
      meta: {'weight': 5},
    );

    final engine = AutoDeduplicationEngine();
    final result = engine.deduplicate([spot1, spot2], keepHighestWeight: true);

    expect(result.length, 1);
    expect(result.first.id, 'b');
  });
}

