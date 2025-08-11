import '../models/v2/training_pack_template_v2.dart';
import '../models/learning_path_stage_model.dart';
import 'pack_registry_service.dart';

/// Resolves missing packs by triggering a focused autogen run.
class MissingPackResolver {
  MissingPackResolver({
    required Future<TrainingPackTemplateV2> Function(String packId, {String? presetId})
        generator,
    PackRegistryService? registry,
  })  : _generator = generator,
        _registry = registry ?? PackRegistryService.instance;

  final Future<TrainingPackTemplateV2> Function(String packId, {String? presetId})
      _generator;
  final PackRegistryService _registry;

  /// Attempts to generate [stage.packId] using an optional [presetId].
  Future<TrainingPackTemplateV2?> resolve(
    LearningPathStageModel stage, {
    String? presetId,
  }) async {
    try {
      final pack =
          await _generator(stage.packId, presetId: presetId);
      _registry.register(pack);
      return pack;
    } catch (_) {
      return null;
    }
  }
}

