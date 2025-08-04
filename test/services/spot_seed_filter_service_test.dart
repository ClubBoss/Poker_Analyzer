import 'package:test/test.dart';
import 'package:poker_analyzer/models/constraint_set.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/spot_seed_filter_service.dart';

void main() {
  final service = SpotSeedFilterService();

  TrainingPackSpot buildSpot({
    String id = '1',
    HeroPosition position = HeroPosition.btn,
    List<String>? board,
    String? villainAction,
    List<String>? tags,
  }) {
    return TrainingPackSpot(
      id: id,
      hand: HandData(position: position),
      board: board ?? const [],
      villainAction: villainAction,
      tags: tags,
    );
  }

  test('filters spots matching all constraints', () {
    final spots = [
      buildSpot(
        id: 'a',
        position: HeroPosition.btn,
        board: ['2h', '2c', '9d'],
        villainAction: 'check',
        tags: ['test'],
      ),
      buildSpot(
        id: 'b',
        position: HeroPosition.co,
        board: ['Ah', 'Kd', '2d'],
        villainAction: 'bet',
        tags: ['other'],
      ),
    ];

    final set = ConstraintSet(
      positions: ['btn'],
      boardTags: ['paired'],
      villainActions: ['check'],
      tags: ['test'],
    );

    final result = service.filter(spots, set);
    expect(result.map((e) => e.id), ['a']);
  });

  test('filters by tags when provided', () {
    final spots = [
      buildSpot(id: 'a', tags: ['keep']),
      buildSpot(id: 'b', tags: ['discard']),
    ];
    final set = ConstraintSet(tags: ['keep']);
    final result = service.filter(spots, set);
    expect(result.map((e) => e.id), ['a']);
  });
}
