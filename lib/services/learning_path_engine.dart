import 'package:collection/collection.dart';

import '../models/learning_path_stage_model.dart';
import '../models/training_attempt.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'tag_mastery_service.dart';
import 'weakness_cluster_engine_v2.dart';
import 'training_pack_generator_v2.dart';

/// Engine driving adaptive learning path stages.
class LearningPathEngine {
  /// Global toggle controlling smart recovery behavior.
  static bool smartRecoveryEnabled = false;

  final WeaknessClusterEngine clusterEngine;
  final TagMasteryService masteryService;
  final TrainingPackGeneratorV2 generator;

  LearningPathEngine({
    this.clusterEngine = const WeaknessClusterEngine(),
    required this.masteryService,
    TrainingPackGeneratorV2? generator,
  }) : generator = generator ?? const TrainingPackGeneratorV2();

  /// Returns the next training pack for [stage].
  ///
  /// When [smartRecoveryEnabled] is true and player's mastery over
  /// [stage.tags] falls below 0.6, a custom recovery pack targeting the
  /// weakest cluster is generated and returned.
  Future<TrainingPackTemplateV2?> nextStage({
    required LearningPathStageModel stage,
    required List<TrainingPackTemplateV2> allPacks,
    required List<TrainingAttempt> attempts,
  }) async {
    final defaultPack =
        allPacks.firstWhereOrNull((p) => p.id == stage.packId);
    if (!smartRecoveryEnabled) return defaultPack;

    final masteryMap = await masteryService.computeMastery();
    final tags = [for (final t in stage.tags) t.toLowerCase()];
    if (tags.isNotEmpty) {
      final values = [for (final t in tags) masteryMap[t] ?? 1.0];
      final avg = values.reduce((a, b) => a + b) / values.length;
      if (avg < 0.6) {
        final clusters = clusterEngine.computeClusters(
          attempts: attempts,
          allPacks: allPacks,
        );
        if (clusters.isNotEmpty) {
          final pack = await generator.generateFromWeakness(
            cluster: clusters.first,
            mastery: masteryMap,
          );
          pack.meta['isAdaptive'] = true;
          return pack;
        }
      }
    }
    return defaultPack;
  }
}
