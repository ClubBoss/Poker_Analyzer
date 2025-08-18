import 'package:flutter/material.dart';

import '../models/training_pack_model.dart';
import '../models/theory_lesson_cluster.dart';
import '../services/theory_lesson_tag_clusterer_service.dart';

/// Visualizes theory clusters related to a training pack.
///
/// Fetches clusters via [TheoryLessonTagClustererService] and shows the first
/// few tags along with sample lessons. Intended for inline debugging within the
/// pack editor.
class InlinePackTheoryClusterViewer extends StatelessWidget {
  final TrainingPackModel pack;
  final TheoryLessonTagClustererService service;
  final int maxLessons;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const InlinePackTheoryClusterViewer({
    super.key,
    required this.pack,
    TheoryLessonTagClustererService? service,
    this.maxLessons = 5,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  }) : service = service ?? TheoryLessonTagClustererService.instance;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TheoryLessonCluster>>(
      future: service.getClusters(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        final clusters = snapshot.data ?? const <TheoryLessonCluster>[];
        if (clusters.isEmpty) {
          return const Text('No theory clusters found');
        }
        final normPackTags = pack.tags.map(_norm).toSet();
        final relevant = clusters.where((c) {
          final clusterTags = c.sharedTags.map(_norm).toSet();
          return clusterTags.any(normPackTags.contains);
        }).toList();
        if (relevant.isEmpty) {
          return const Text('No related clusters for this pack');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListView.builder(
              shrinkWrap: shrinkWrap,
              physics: physics,
              itemCount: relevant.length,
              itemBuilder: (context, index) {
                final cluster = relevant[index];
                final clusterTags = cluster.sharedTags.map(_norm).toSet();
                final matched = clusterTags.where(normPackTags.contains).length;
                return ExpansionTile(
                  title: Text(
                    '${_tagSummary(cluster)} • $matched/${cluster.sharedTags.length}',
                  ),
                  children: [
                    for (final lesson in cluster.lessons.take(maxLessons))
                      ListTile(dense: true, title: Text(lesson.title)),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  String _norm(String s) => s.trim().toLowerCase();

  String _tagSummary(TheoryLessonCluster c) {
    final tags = c.sharedTags.take(3).toList();
    return tags.isEmpty ? 'Cluster' : tags.join(', ');
  }
}
