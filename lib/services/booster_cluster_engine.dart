import 'dart:io';
import 'package:path/path.dart' as p;

import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/game_type.dart';
import '../core/training/engine/training_type_engine.dart';
import 'booster_similarity_engine.dart';

class SpotCluster {
  final List<TrainingPackSpot> spots;
  final String clusterId;

  SpotCluster({required this.spots, required this.clusterId});
}

class BoosterClusterEngine {
  final BoosterSimilarityEngine _engine;
  final double _threshold;

  const BoosterClusterEngine(
      {BoosterSimilarityEngine? engine, double threshold = 0.85})
      : _engine = engine ?? const BoosterSimilarityEngine(),
        _threshold = threshold;

  List<SpotCluster> analyzeSpots(List<TrainingPackSpot> spots,
      {double? threshold}) {
    final thr = threshold ?? _threshold;
    if (spots.isEmpty) return [];
    final pairs = _engine.analyzeSpots(spots, threshold: thr);
    final adj = <String, Set<String>>{for (final s in spots) s.id: <String>{}};
    for (final r in pairs) {
      if (r.similarity < thr) break;
      adj[r.idA]!.add(r.idB);
      adj[r.idB]!.add(r.idA);
    }
    final idToSpot = {for (final s in spots) s.id: s};
    final visited = <String>{};
    final clusters = <SpotCluster>[];
    var idx = 1;
    for (final id in idToSpot.keys) {
      if (visited.contains(id)) continue;
      final stack = <String>[id];
      final cSpots = <TrainingPackSpot>[];
      visited.add(id);
      while (stack.isNotEmpty) {
        final cur = stack.removeLast();
        final spot = idToSpot[cur];
        if (spot != null) cSpots.add(spot);
        for (final n in adj[cur] ?? {}) {
          if (!visited.contains(n)) {
            visited.add(n);
            stack.add(n);
          }
        }
      }
      clusters.add(SpotCluster(spots: cSpots, clusterId: 'cluster_$idx'));
      idx++;
    }
    clusters.sort((a, b) => b.spots.length.compareTo(a.spots.length));
    return clusters;
  }

  List<SpotCluster> analyzePack(TrainingPackTemplateV2 pack,
      {double? threshold}) {
    return analyzeSpots(pack.spots, threshold: threshold);
  }

  Future<int> saveClustersToFolder(List<SpotCluster> clusters,
      {String dir = 'yaml_out/clusters'}) async {
    if (clusters.isEmpty) return 0;
    final directory = Directory(dir);
    await directory.create(recursive: true);
    var count = 0;
    for (final c in clusters) {
      final tpl = TrainingPackTemplateV2(
        id: c.clusterId,
        name: c.clusterId,
        trainingType: TrainingType.pushFold,
        spots: c.spots,
        spotCount: c.spots.length,
        created: DateTime.now(),
        gameType: GameType.tournament,
        meta: const {'schemaVersion': '2.0.0'},
      );
      tpl.trainingType = const TrainingTypeEngine().detectTrainingType(tpl);
      final file = File(p.join(directory.path, '${c.clusterId}.yaml'));
      await file.writeAsString(tpl.toYamlString());
      count++;
    }
    return count;
  }
}
