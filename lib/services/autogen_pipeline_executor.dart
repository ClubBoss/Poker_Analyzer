import 'dart:io';

import '../models/training_pack_template_set.dart';
import '../models/inline_theory_entry.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/training_pack_model.dart';
import '../models/game_type.dart';
import '../models/autogen_status.dart';

import 'auto_deduplication_engine.dart';
import 'training_pack_auto_generator.dart';
import 'yaml_pack_exporter.dart';
import 'skill_tag_coverage_tracker.dart';
import 'skill_tag_coverage_tracker_service.dart';
import 'autogen_stats_dashboard_service.dart';
import 'autogen_status_dashboard_service.dart';
import 'inline_theory_link_auto_injector.dart';
import 'board_texture_classifier.dart';
import 'skill_tree_auto_linker.dart';
import 'training_pack_fingerprint_generator.dart';
import 'icm_scenario_library_injector.dart';
import 'pack_quality_gatekeeper_service.dart';
import 'autogen_run_history_logger_service.dart';
import 'autogen_pipeline_debug_stats_service.dart';
import 'autogen_pipeline_event_logger_service.dart';

/// Centralized orchestrator running the full auto-generation pipeline.
class AutogenPipelineExecutor {
  late final TrainingPackAutoGenerator generator;
  final AutoDeduplicationEngine dedup;
  final YamlPackExporter exporter;
  final SkillTagCoverageTracker coverage;
  final SkillTagCoverageTrackerService coverageService;
  final InlineTheoryLinkAutoInjector theoryInjector;
  final BoardTextureClassifier? boardClassifier;
  final SkillTreeAutoLinker skillLinker;
  final TrainingPackFingerprintGenerator fingerprintGenerator;
  final IOSink _fingerprintLog;
  final AutogenStatsDashboardService dashboard;
  final AutogenStatusDashboardService status;
  final ICMScenarioLibraryInjector? icmInjector;
  final PackQualityGatekeeperService gatekeeper;
  final AutogenRunHistoryLoggerService runHistory;

  AutogenPipelineExecutor({
    TrainingPackAutoGenerator? generator,
    AutoDeduplicationEngine? dedup,
    YamlPackExporter? exporter,
    SkillTagCoverageTracker? coverage,
    SkillTagCoverageTrackerService? coverageService,
    InlineTheoryLinkAutoInjector? theoryInjector,
    BoardTextureClassifier? boardClassifier,
    SkillTreeAutoLinker? skillLinker,
    TrainingPackFingerprintGenerator? fingerprintGenerator,
    IOSink? fingerprintLog,
    AutogenStatsDashboardService? dashboard,
    AutogenStatusDashboardService? status,
    ICMScenarioLibraryInjector? icmInjector,
    PackQualityGatekeeperService? gatekeeper,
    AutogenRunHistoryLoggerService? runHistory,
  })  : dedup = dedup ?? AutoDeduplicationEngine(),
        exporter = exporter ?? const YamlPackExporter(),
        coverage = coverage ?? SkillTagCoverageTracker(),
        coverageService = coverageService ?? SkillTagCoverageTrackerService(),
        theoryInjector = theoryInjector ?? InlineTheoryLinkAutoInjector(),
        boardClassifier = boardClassifier,
        skillLinker = skillLinker ?? const SkillTreeAutoLinker(),
        fingerprintGenerator =
            fingerprintGenerator ?? const TrainingPackFingerprintGenerator(),
        _fingerprintLog = fingerprintLog ??
            File(
              'generated_pack_fingerprints.log',
            ).openWrite(mode: FileMode.append),
        dashboard = dashboard ?? AutogenStatsDashboardService(),
        status = status ?? AutogenStatusDashboardService(),
        icmInjector = icmInjector,
        gatekeeper = gatekeeper ?? const PackQualityGatekeeperService(),
        runHistory = runHistory ?? const AutogenRunHistoryLoggerService() {
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
    var generatedCount = 0;
    var rejectedCount = 0;
    var totalQualityScore = 0.0;
    var processedCount = 0;
    status.update(
      'pipeline',
      const AutogenStatus(
        isRunning: true,
        currentStage: 'init',
        progress: 0,
      ),
    );
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
      for (var i = 0; i < sets.length; i++) {
        final set = sets[i];
        status.update(
          'pipeline',
          AutogenStatus(
            isRunning: true,
            currentStage: 'template:${set.baseSpot.id}',
            progress: i / sets.length,
          ),
        );
        if (generator.shouldAbort) break;
        var spots = await generator.generate(set, theoryIndex: theoryIndex);
        if (generator.shouldAbort) break;
        if (spots.isEmpty) {
          status.update(
            'pipeline',
            AutogenStatus(
              isRunning: true,
              currentStage: 'template:${set.baseSpot.id}',
              progress: (i + 1) / sets.length,
            ),
          );
          continue;
        }
        AutogenPipelineDebugStatsService.incrementGenerated();
        AutogenPipelineEventLoggerService.log(
          'generated',
          'Generated ${spots.length} spots for template ${set.baseSpot.id}',
        );

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

        var model = TrainingPackModel(
          id: pack.id,
          title: pack.name,
          spots: spots,
          tags: List<String>.from(pack.tags),
          metadata: Map<String, dynamic>.from(pack.meta),
        );
        if (icmInjector != null) {
          model = icmInjector!.injectICMSpots(model);
          pack.spots = model.spots;
          pack.spotCount = model.spots.length;
          spots = model.spots;
        }
        final accepted = gatekeeper.isQualityAcceptable(model);
        final score = model.metadata['qualityScore'] as double? ?? 0.0;
        totalQualityScore += score;
        processedCount++;
        if (!accepted) {
          rejectedCount++;
          continue;
        }
        generatedCount++;
        AutogenPipelineDebugStatsService.incrementCurated();
        AutogenPipelineEventLoggerService.log(
          'curated',
          'Curated pack ${pack.id} with ${spots.length} spots',
        );
        pack.meta['qualityScore'] = score;

        coverage.analyzePack(model);
        dashboard.recordCoverage(coverage.aggregateReport);
        await coverageService.logPack(model);

        final file = await exporter.export(pack);
        files.add(file);

        dashboard.recordPack(spots.length);
        final fp = fingerprintGenerator.generateFromTemplate(pack);
        _fingerprintLog.writeln(fp);
        status.update(
          'pipeline',
          AutogenStatus(
            isRunning: true,
            currentStage: 'template:${set.baseSpot.id}',
            progress: (i + 1) / sets.length,
          ),
        );
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
      final avgQuality =
          processedCount == 0 ? 0.0 : totalQualityScore / processedCount;
      await runHistory.logRun(
        generated: generatedCount,
        rejected: rejectedCount,
        avgScore: avgQuality,
      );
      status.update(
        'pipeline',
        const AutogenStatus(
          isRunning: false,
          currentStage: 'complete',
          progress: 1,
        ),
      );
      return files;
    } catch (e) {
      status.update(
        'pipeline',
        AutogenStatus(
          isRunning: false,
          currentStage: 'error',
          progress: 0,
          lastError: e.toString(),
        ),
      );
      rethrow;
    }
  }
}
