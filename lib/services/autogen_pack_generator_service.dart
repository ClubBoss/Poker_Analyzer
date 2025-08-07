import 'dart:io';

import '../models/training_pack_template_set.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/game_type.dart';
import 'auto_deduplication_engine.dart';
import 'training_pack_auto_generator.dart';
import 'yaml_pack_exporter.dart';
import 'pack_quality_gatekeeper_service.dart';
import '../models/training_pack_model.dart';
import 'pack_generation_metrics_tracker_service.dart';

/// Generates training packs from template sets while automatically skipping
/// duplicate spots and exporting the results to YAML.
class AutogenPackGeneratorService {
  late final TrainingPackAutoGenerator _generator;
  final YamlPackExporter _exporter;
  final AutoDeduplicationEngine _dedup;
  final PackQualityGatekeeperService _gatekeeper;
  final PackGenerationMetricsTrackerService _metrics;

  AutogenPackGeneratorService({
    TrainingPackAutoGenerator? generator,
    YamlPackExporter? exporter,
    AutoDeduplicationEngine? dedup,
    PackQualityGatekeeperService? gatekeeper,
    PackGenerationMetricsTrackerService? metrics,
  })  : _dedup = dedup ?? AutoDeduplicationEngine(),
        _exporter = exporter ?? const YamlPackExporter(),
        _gatekeeper = gatekeeper ?? const PackQualityGatekeeperService(),
        _metrics = metrics ?? const PackGenerationMetricsTrackerService() {
    _generator = generator ?? TrainingPackAutoGenerator(dedup: _dedup);
  }

  /// Generates packs from [sets].
  ///
  /// [existingYamlPath] points to a directory containing previously exported
  /// YAML packs. These are loaded into memory so their spots can be registered
  /// with the deduplication engine, ensuring only unique spots are exported.
  Future<List<File>> generate(
    List<TrainingPackTemplateSet> sets, {
    String existingYamlPath = '',
  }) async {
    if (existingYamlPath.isNotEmpty) {
      final dir = Directory(existingYamlPath);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File &&
              (entity.path.endsWith('.yaml') || entity.path.endsWith('.yml'))) {
            final yaml = await entity.readAsString();
            final tpl = TrainingPackTemplateV2.fromYaml(yaml);
            _dedup.addExisting(tpl.spots);
          }
        }
      }
    }

    final files = <File>[];
    for (final set in sets) {
      final spots = _generator.generate(set);
      if (spots.isEmpty) continue;
      final base = set.baseSpot;
      final pack = TrainingPackTemplateV2(
        id: base.id,
        name: base.title.isNotEmpty ? base.title : base.id,
        trainingType: TrainingType.custom,
        spots: spots,
        spotCount: spots.length,
        tags: List<String>.from(base.tags),
        gameType: GameType.cash,
        bb: base.hand.stacks['0']?.toInt() ?? 0,
        positions: [base.hand.position.name],
        meta: Map<String, dynamic>.from(base.meta),
      );
      pack.meta['uniqueSpotsOnly'] = true;
      final model = TrainingPackModel(
        id: pack.id,
        title: pack.name,
        spots: pack.spots,
        tags: pack.tags,
        metadata: Map<String, dynamic>.from(pack.meta),
      );
      final accepted = _gatekeeper.isQualityAcceptable(model);
      final score = model.metadata['qualityScore'] as double? ?? 0.0;
      await _metrics.recordGenerationResult(score: score, accepted: accepted);
      if (!accepted) {
        continue;
      }
      pack.meta['qualityScore'] = score;
      files.add(await _exporter.export(pack));
    }

    await _dedup.dispose();
    return files;
  }
}
