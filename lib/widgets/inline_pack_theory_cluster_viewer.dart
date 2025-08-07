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

  const InlinePackTheoryClusterViewer({
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
        final related = clusters
            .where((c) => c.sharedTags.any(tagSet.contains))
            .toList();
        if (related.isEmpty) {
          return const Text('No related theory clusters');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final c in related)
              ExpansionTile(
                title: Text('${_tagSummary(c)} (${c.lessons.length})'),
                children: [
                  for (final lesson in c.lessons.take(5))
                    ListTile(
                      dense: true,
                      title: Text(lesson.title),
                    ),
                ],
              ),
          ],
        );
      },
    );
  }

  String _tagSummary(TheoryLessonCluster cluster) {
    final tags = cluster.sharedTags.take(3).toList();
    return tags.isEmpty ? 'Cluster' : tags.join(', ');
  }
}
