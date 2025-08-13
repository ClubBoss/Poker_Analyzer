import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/services/booster_cluster_engine.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';

TrainingPackSpot _spot(String id, String cards, HeroPosition pos) {
  final hand = HandData.fromSimpleInput(cards, pos, 10);
  return TrainingPackSpot(id: id, hand: hand);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('clusters similar spots', () {
    final s1 = _spot('a', 'AhKh', HeroPosition.btn);
    final s2 = _spot('b', 'AhKh', HeroPosition.btn);
    final s3 = _spot('c', '9c8c', HeroPosition.sb);

    const engine = BoosterClusterEngine();
    final clusters = engine.analyzeSpots([s1, s2, s3], threshold: 0.8);

    expect(clusters.length, 2);
    expect(clusters.first.spots.length, 2);
    expect(clusters.last.spots.length, 1);
  });
}
