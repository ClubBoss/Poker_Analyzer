import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/training_pack_model.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/services/pack_quality_score_calculator_service.dart';

void main() {
  test('calculates and stores quality score', () {
    final spots = [
      TrainingPackSpot(
        id: '1',
        tags: ['a', 'b'],
        board: ['Ah', 'Kd', 'Qs'],
        correctAction: 'fold',
        theoryRefs: ['T1'],
      ),
      TrainingPackSpot(
        id: '2',
        tags: ['a'],
        board: ['2h', '3d', '5c'],
        correctAction: 'call',
        theoryRefs: ['T2'],
      ),
      TrainingPackSpot(
        id: '3',
        tags: ['c'],
        board: ['Ah', 'Kd', 'Qs'],
        correctAction: 'fold',
        theoryRefs: [],
      ),
    ];

    final pack = TrainingPackModel(id: 'p', title: 'Test', spots: spots);
    final service = PackQualityScoreCalculatorService();
    final score = service.calculateQualityScore(pack);

    expect(score, closeTo(0.7549, 0.0001));
    expect(pack.metadata['qualityScore'], closeTo(score, 1e-9));
  });
}
