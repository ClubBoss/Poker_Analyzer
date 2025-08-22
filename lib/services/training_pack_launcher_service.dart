import '../models/learning_path_node_v2.dart';
import '../core/training/library/training_pack_library_v2.dart';
import 'training_session_launcher.dart';

/// Launches a training pack referenced by a learning path node.
class TrainingPackLauncherService {
  final TrainingSessionLauncher launcher;

  TrainingPackLauncherService({
    this.launcher = const TrainingSessionLauncher(),
  });

  /// Launches training for [node]. Supports dynamic packs by applying
  /// [LearningPathNodeV2.dynamicMeta] if present.
  Future<void> launch(LearningPathNodeV2 node) async {
    if (node.type != LearningPathNodeType.training) return;
    final String? packId = node.trainingPackTemplateId ?? node.dynamicPackId;
    if (packId == null) return;

    await TrainingPackLibraryV2.instance.loadFromFolder();
    final template = TrainingPackLibraryV2.instance.getById(packId);
    if (template == null) return;

    // Apply dynamic metadata if provided by the node.
    if (node.dynamicMeta is Map<String, dynamic>) {
      final meta = Map<String, dynamic>.from(node.dynamicMeta!);
      if (meta['dynamicParams'] is Map) {
        template.meta['dynamicParams'] = Map<String, dynamic>.from(
          meta['dynamicParams'] as Map,
        );
      }
    }

    // Ensure dynamic spots are freshly generated for dynamic packs.
    if (template.dynamicSpots.isNotEmpty ||
        template.meta['dynamicParams'] is Map) {
      template.regenerateDynamicSpots();
    }

    await launcher.launch(template);
  }
}
