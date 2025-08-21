import 'package:flutter_test/flutter_test.dart';
import 'package:poker_analyzer/models/v2/training_pack_spot.dart';
import 'package:poker_analyzer/models/v2/hand_data.dart';
import 'package:poker_analyzer/models/v2/hero_position.dart';
import 'package:poker_analyzer/services/spot_duplicate_finder.dart';

HandData _hand(String pos, String hero, String board) {
  final b = <String>[];
  for (var i = 0; i + 1 < board.length; i += 2) {
    b.add(board.substring(i, i + 2));
  }
  final hc =
      hero.length == 4 ? '${hero.substring(0, 2)} ${hero.substring(2)}' : hero;
  return HandData(position: parseHeroPosition(pos), heroCards: hc, board: b);
}

void main() {
  test('detect duplicate spots', () {
    final s1 = TrainingPackSpot(id: 'a', hand: _hand('BTN', 'AhKh', 'KdQsJs'));
    final s2 = TrainingPackSpot(id: 'b', hand: _hand('BTN', 'AhKh', 'KdQsJs'));
    final s3 = TrainingPackSpot(id: 'c', hand: _hand('SB', 'AhKh', 'KdQsJs'));
    final list = [s1, s2, s3];
    final groups = duplicateSpotGroupsStatic(list);
    expect(groups.length, 1);
    expect(groups.first, containsAll(<int>[0, 1]));
  });
}
