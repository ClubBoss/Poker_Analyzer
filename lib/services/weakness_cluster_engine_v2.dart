import '../models/training_attempt.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/hero_position.dart';

class WeaknessCluster {
  final String label;
  final List<String> spotIds;
  final double avgAccuracy;

  const WeaknessCluster({
    required this.label,
    required this.spotIds,
    required this.avgAccuracy,
  });
}

class WeaknessClusterEngine {
  const WeaknessClusterEngine();

  List<WeaknessCluster> computeClusters({
    required List<TrainingAttempt> attempts,
    required List<TrainingPackTemplateV2> allPacks,
  }) {
    if (attempts.isEmpty || allPacks.isEmpty) return [];

    final spotMap = <String, Map<String, TrainingPackSpot>>{};
    for (final p in allPacks) {
      spotMap[p.id] = {for (final s in p.spots) s.id: s};
    }

    final data = <String, _ClusterData>{};

    void add(String label, TrainingAttempt a) {
      final d = data.putIfAbsent(label, () => _ClusterData());
      d.totalAccuracy += a.accuracy;
      d.count += 1;
      d.spotIds.add(a.spotId);
    }

    for (final a in attempts) {
      if (a.accuracy >= 0.7) continue;
      final spot = spotMap[a.packId]?[a.spotId];
      if (spot == null) continue;

      // Hero position cluster
      final pos = spot.hand.position;
      if (pos != HeroPosition.unknown) {
        add(pos.label, a);
      }

      // Tag clusters
      for (final t in spot.tags) {
        final tag = t.trim();
        if (tag.isNotEmpty) add(tag, a);
      }

      // Board texture cluster
      final boardType = _classifyBoard(spot.hand.board);
      if (boardType.isNotEmpty) add(boardType, a);
    }

    final results = <WeaknessCluster>[];
    data.forEach((label, d) {
      if (d.spotIds.length >= 3 && d.count > 0) {
        results.add(
          WeaknessCluster(
            label: label,
            spotIds: d.spotIds.toList(),
            avgAccuracy: d.totalAccuracy / d.count,
          ),
        );
      }
    });

    results.sort((a, b) => a.avgAccuracy.compareTo(b.avgAccuracy));
    return results;
  }

  String _classifyBoard(List<String> board) {
    if (board.length < 3) return '';
    final suits = board.map((c) => c.substring(1)).toSet();
    if (suits.length == 1) return 'Mono';
    final ranks = board.map((c) => c[0].toUpperCase()).toList();
    final counts = <String, int>{};
    for (final r in ranks) {
      counts[r] = (counts[r] ?? 0) + 1;
    }
    if (counts.values.any((c) => c >= 2)) {
      final values = ranks.map(_rankValue).toList();
      final high = values.reduce((a, b) => a > b ? a : b);
      if (high <= _rankValue('9')) return 'Low paired';
      return 'Paired';
    }
    final values = ranks.map(_rankValue).toList()..sort();
    if (values.last <= _rankValue('T') && values.last - values.first <= 4) {
      return 'Low connected';
    }
    return 'Dry high';
  }

  int _rankValue(String r) {
    const order = '23456789TJQKA';
    return order.indexOf(r) + 2;
  }
}

class _ClusterData {
  double totalAccuracy = 0;
  int count = 0;
  final Set<String> spotIds = {};
}
