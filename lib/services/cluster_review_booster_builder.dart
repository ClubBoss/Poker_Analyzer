import 'package:uuid/uuid.dart';

import '../models/weak_cluster_info.dart';
import '../models/theory_mini_lesson_node.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../core/training/engine/training_type_engine.dart';
import '../core/training/generation/training_pack_source_tagger.dart';

/// Builds review training packs from weak theory clusters.
class ClusterReviewBoosterBuilder {
  final Uuid _uuid;
  final TrainingPackSourceTagger _tagger;
  final TrainingTypeEngine _typeEngine;

  const ClusterReviewBoosterBuilder({
    Uuid uuid = const Uuid(),
    TrainingPackSourceTagger tagger = const TrainingPackSourceTagger(),
    TrainingTypeEngine typeEngine = const TrainingTypeEngine(),
  }) : _uuid = uuid,
       _tagger = tagger,
       _typeEngine = typeEngine;

  /// Generates a [TrainingPackTemplateV2] containing lessons from [weakCluster].
  ///
  /// Lessons already completed with high accuracy are excluded. Tag accuracy
  /// below `0.7` is treated as weak.
  TrainingPackTemplateV2 build({
    required WeakClusterInfo weakCluster,
    required Map<String, TheoryMiniLessonNode> allLessons,
    Set<String> completedLessons = const {},
    Map<String, double> tagAccuracy = const {},
  }) {
    final tags = weakCluster.cluster.sharedTags
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .toSet();

    final relevant = allLessons.values
        .where((l) {
          final lessonTags = l.tags
              .map((t) => t.trim().toLowerCase())
              .where((t) => t.isNotEmpty);
          return lessonTags.any(tags.contains);
        })
        .where((l) {
          if (!completedLessons.contains(l.id)) return true;
          for (final t in l.tags) {
            final acc = tagAccuracy[t.trim().toLowerCase()] ?? 1.0;
            if (acc < 0.7) return true;
          }
          return false;
        })
        .toList();

    final spots = <TrainingPackSpot>[
      for (final l in relevant)
        TrainingPackSpot(
          id: l.id,
          type: 'theory',
          title: l.resolvedTitle,
          note: l.resolvedContent,
          tags: List<String>.from(l.tags),
          meta: {'lessonId': l.id},
        ),
    ];

    final tpl = TrainingPackTemplateV2(
      id: _uuid.v4(),
      name: 'Review: ${tags.join(', ')}',
      trainingType: TrainingType.theory,
      tags: List<String>.from(tags),
      spots: spots,
      spotCount: spots.length,
      created: DateTime.now(),
      meta: {
        'generatedFromClusterId': weakCluster.cluster.entryPointIds.join(','),
      },
    );

    _tagger.tag(tpl, source: 'booster');
    tpl.trainingType = _typeEngine.detectTrainingType(tpl);
    return tpl;
  }
}
