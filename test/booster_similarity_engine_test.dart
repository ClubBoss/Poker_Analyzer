import 'package:test/test.dart';
import 'package:poker_analyzer/services/booster_similarity_engine.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';

TrainingPackSpot _spot(
  String id,
  String cards,
  HeroPosition pos, {
  List<String>? board,
  double? ev,
}) {
  final hand = HandData.fromSimpleInput(cards, pos, 10);
  if (board != null) hand.board.addAll(board);
  if (ev != null) {
    final acts = hand.actions[0];
    if (acts.isNotEmpty) {
      acts[0] = acts.first.copyWith(ev: ev);
    }
  }
  return TrainingPackSpot(id: id, hand: hand);
}

void main() {
  test('analyzeSpots detects similar pair', () {
    final s1 = _spot(
      'a',
      'AhKh',
      HeroPosition.btn,
      board: ['Kd', 'Qs', 'Js'],
      ev: 0.5,
    );
    final s2 = _spot(
      'b',
      'AhKh',
      HeroPosition.btn,
      board: ['Kd', 'Qs', 'Js'],
      ev: 0.52,
    );
    final s3 = _spot(
      'c',
      '9c8c',
      HeroPosition.sb,
      board: ['2h', '3d', '4s'],
      ev: -0.3,
    );

    const engine = BoosterSimilarityEngine();
    final res = engine.analyzeSpots([s1, s2, s3], threshold: 0.8);

    expect(res.length, 1);
    expect(res.first.idA, 'a');
    expect(res.first.idB, 'b');
  });
}
