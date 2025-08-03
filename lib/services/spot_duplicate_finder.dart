import '../models/v2/training_pack_spot.dart';

List<List<int>> duplicateSpotGroupsStatic(List<TrainingPackSpot> spots) {
  final map = <String, List<int>>{};
  for (var i = 0; i < spots.length; i++) {
    final h = spots[i].hand;
    final hero = h.heroCards.replaceAll(' ', '');
    final board = h.board.join();
    final key = '${h.position.name}-$hero-$board';
    map.putIfAbsent(key, () => []).add(i);
  }
  return [for (final g in map.values) if (g.length > 1) g];
}
