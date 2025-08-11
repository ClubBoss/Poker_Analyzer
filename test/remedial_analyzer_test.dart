import 'package:test/test.dart';
import 'package:poker_analyzer/services/remedial_analyzer.dart';
import 'package:poker_analyzer/models/training_spot_attempt.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';

void main() {
  test('RemedialAnalyzer produces spec with top tags and textures', () {
    final spot1 = TrainingPackSpot(
      id: 's1',
      tags: ['tagA', 'tagB'],
      hand: HandData(board: ['As', 'Ks', 'Qs']),
      board: ['As', 'Ks', 'Qs'],
      street: 1,
    );
    final spot2 = TrainingPackSpot(
      id: 's2',
      tags: ['tagA', 'tagC'],
      hand: HandData(board: ['2h', '7d', '7c']),
      board: ['2h', '7d', '7c'],
      street: 1,
    );
    final attempts = [
      TrainingSpotAttempt(
          spot: spot1, userAction: 'fold', correctAction: 'call', evDiff: -1),
      TrainingSpotAttempt(
          spot: spot2, userAction: 'fold', correctAction: 'call', evDiff: -1),
      TrainingSpotAttempt(
          spot: spot1, userAction: 'call', correctAction: 'call', evDiff: 0),
    ];

    final analyzer = RemedialAnalyzer();
    final spec = analyzer.analyze(attempts, targetAccuracy: 0.8);

    expect(spec.topTags.first, 'tagA');
    expect(spec.topTags.length, 3);
    expect(spec.textureCounts.isNotEmpty, true);
    expect(spec.streetBias, 1);
    expect(spec.minAccuracyTarget, 0.8);
  });
}
