import 'package:flutter/material.dart';

import '../models/training_pack_model.dart';
import '../models/theory_lesson_cluster.dart';
import '../services/theory_lesson_tag_clusterer_service.dart';

/// Visualizes theory cluster coverage for a given training pack.
///
/// Computes the fraction of tags from each cluster that are present in the
/// [TrainingPackModel]'s tags and displays a compact heatmap style list sorted
/// by coverage.
class TheoryClusterPackHeatmapWidget extends StatelessWidget {
  final TrainingPackModel pack;
  final TheoryLessonTagClustererService service;

  const TheoryClusterPackHeatmapWidget({
    super.key,
    required this.pack,
    TheoryLessonTagClustererService? service,
  }) : service = service ?? TheoryLessonTagClustererService.instance;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TheoryLessonCluster>>(
      future: service.getClusters(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final clusters = snapshot.data ?? const [];
        final tagSet = pack.tags.toSet();
        final entries = clusters.map((c) {
          final shared = c.sharedTags;
          final matched = shared.where(tagSet.contains).length;
          final coverage = shared.isEmpty ? 0.0 : matched / shared.length;
          return _ClusterCoverage(cluster: c, coverage: coverage);
        }).toList()
          ..sort((a, b) => b.coverage.compareTo(a.coverage));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in entries) _ClusterCoverageRow(entry: entry),
          ],
        );
      },
    );
  }
}

class _ClusterCoverage {
  final TheoryLessonCluster cluster;
  final double coverage;

  _ClusterCoverage({required this.cluster, required this.coverage});
}

class _ClusterCoverageRow extends StatelessWidget {
  final _ClusterCoverage entry;

  const _ClusterCoverageRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final percent = (entry.coverage * 100).round();
    final label = entry.cluster.sharedTags.take(3).join(', ');
    final color =
        Color.lerp(Colors.red, Colors.green, entry.coverage) ?? Colors.red;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label.isEmpty ? 'Cluster' : label)),
          SizedBox(
            width: 60,
            child: LinearProgressIndicator(
              value: entry.coverage,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(width: 30, child: Text('$percent%')),
        ],
      ),
    );
  }
}
