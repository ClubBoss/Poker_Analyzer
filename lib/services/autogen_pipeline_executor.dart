import 'dart:io';

import '../models/training_pack_template_set.dart';
import '../models/inline_theory_entry.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/training_pack_model.dart';
import '../models/game_type.dart';

import 'auto_deduplication_engine.dart';
import 'training_pack_auto_generator.dart';
import 'yaml_pack_exporter.dart';
import 'skill_tag_coverage_tracker.dart';
import 'autogen_stats_dashboard_service.dart';
import 'autogen_status_dashboard_service.dart';
import 'inline_theory_link_auto_injector.dart';
import 'board_texture_classifier.dart';
import 'skill_tree_auto_linker.dart';
import 'training_pack_fingerprint_generator.dart';

/// Centralized orchestrator running the full auto-generation pipeline.
class AutogenPipelineExecutor {
  late final TrainingPackAutoGenerator generator;
  final AutoDeduplicationEngine dedup;
  final YamlPackExporter exporter;
  final SkillTagCoverageTracker coverage;
  final InlineTheoryLinkAutoInjector theoryInjector;
  final BoardTextureClassifier? boardClassifier;
  final SkillTreeAutoLinker skillLinker;
  final TrainingPackFingerprintGenerator fingerprintGenerator;
  final IOSink _fingerprintLog;
  final AutogenStatsDashboardService dashboard;
  final AutogenStatusDashboardService status;

  AutogenPipelineExecutor({
    TrainingPackAutoGenerator? generator,
    AutoDeduplicationEngine? dedup,
    YamlPackExporter? exporter,
    SkillTagCoverageTracker? coverage,
    InlineTheoryLinkAutoInjector? theoryInjector,
    BoardTextureClassifier? boardClassifier,
    SkillTreeAutoLinker? skillLinker,
    TrainingPackFingerprintGenerator? fingerprintGenerator,
    IOSink? fingerprintLog,
    AutogenStatsDashboardService? dashboard,
    AutogenStatusDashboardService? status,
  }) : dedup = dedup ?? AutoDeduplicationEngine(),
       exporter = exporter ?? const YamlPackExporter(),
       coverage = coverage ?? SkillTagCoverageTracker(),
       theoryInjector = theoryInjector ?? InlineTheoryLinkAutoInjector(),
       boardClassifier = boardClassifier,
       skillLinker = skillLinker ?? const SkillTreeAutoLinker(),
       fingerprintGenerator =
           fingerprintGenerator ?? const TrainingPackFingerprintGenerator(),
       _fingerprintLog =
           fingerprintLog ??
           File(
             'generated_pack_fingerprints.log',
           ).openWrite(mode: FileMode.append),
       dashboard = dashboard ?? AutogenStatsDashboardService(),
       status = status ?? AutogenStatusDashboardService() {
    this.generator = generator ?? TrainingPackAutoGenerator(dedup: this.dedup);
  }

  /// Runs the pipeline on [sets].
  Future<List<File>> execute(
    List<TrainingPackTemplateSet> sets, {
    String existingYamlPath = '',
    Map<String, InlineTheoryEntry> theoryIndex = const {},
  }) async {
    // Load existing YAMLs to prime deduplication engine.
    dashboard.start();
    status.start();
    if (existingYamlPath.isNotEmpty) {
      final dir = Directory(existingYamlPath);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File &&
              (entity.path.endsWith('.yaml') || entity.path.endsWith('.yml'))) {
            final yaml = await entity.readAsString();
            final tpl = TrainingPackTemplateV2.fromYaml(yaml);
            dedup.addExisting(tpl.spots);
          }
        }
      }
    }

    final files = <File>[];
    try {
      for (final set in sets) {
        status.stage(
          'template:${set.baseSpot.id}',
          templateSet: set.baseSpot.id,
        );
        if (generator.shouldAbort) break;
        final spots = generator.generate(set, theoryIndex: theoryIndex);
        if (generator.shouldAbort) break;
        if (spots.isEmpty) continue;

        theoryInjector.injectAll(spots, theoryIndex);
        boardClassifier?.classifyAll(spots);
        skillLinker.linkAll(spots);

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
          spots: spots,
          tags: List<String>.from(pack.tags),
          metadata: Map<String, dynamic>.from(pack.meta),
        );
        coverage.analyzePack(model);
        dashboard.recordCoverage(coverage.aggregateReport);

        final file = await exporter.export(pack);
        files.add(file);

        dashboard.recordPack(spots.length);
        final fp = fingerprintGenerator.generateFromTemplate(pack);
        _fingerprintLog.writeln(fp);
      }

      dashboard.recordSkipped(dedup.skippedCount);
      await dedup.dispose();
      await coverage.logSummary();
      await _fingerprintLog.flush();
      await _fingerprintLog.close();
      await dashboard.logFinalStats(
        coverage.aggregateReport,
        yamlFiles: files.length,
      );
      await status.complete();
      return files;
    } catch (e) {
      await status.fail(e.toString());
      rethrow;
    }
  }
}
