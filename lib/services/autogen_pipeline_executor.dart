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
import 'pack_fingerprint_comparer.dart';
import 'spot_fingerprint_generator.dart';
import 'deduplication_policy_engine.dart';
import 'targeted_pack_booster_engine.dart';
import 'auto_skill_gap_clusterer.dart';
import 'auto_format_selector.dart';
import 'theory_auto_injector.dart';

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
  final ICMScenarioLibraryInjector? icmInjector;
  final PackQualityGatekeeperService gatekeeper;
  final AutogenRunHistoryLoggerService runHistory;
  final PackFingerprintComparer packComparer;
  final DeduplicationPolicyEngine policyEngine;
  final TargetedPackBoosterEngine boosterEngine;
  final AutoFormatSelector formatSelector;
  final TheoryAutoInjector autoInjector;

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
    ICMScenarioLibraryInjector? icmInjector,
    PackQualityGatekeeperService? gatekeeper,
    AutogenRunHistoryLoggerService? runHistory,
    PackFingerprintComparer? packComparer,
    DeduplicationPolicyEngine? policyEngine,
    TargetedPackBoosterEngine? boosterEngine,
    AutoFormatSelector? formatSelector,
    TheoryAutoInjector? autoInjector,
  })  : dedup = dedup ?? AutoDeduplicationEngine(),
        exporter = exporter ?? const YamlPackExporter(),
        coverage = coverage ?? SkillTagCoverageTracker(),
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
        runHistory = runHistory ?? const AutogenRunHistoryLoggerService(),
        packComparer = packComparer ?? const PackFingerprintComparer(),
        policyEngine = policyEngine ?? DeduplicationPolicyEngine(),
        boosterEngine = boosterEngine ?? TargetedPackBoosterEngine(),
        formatSelector = formatSelector ?? AutoFormatSelector(),
        autoInjector = autoInjector ?? TheoryAutoInjector() {
    this.generator = generator ?? TrainingPackAutoGenerator(dedup: this.dedup);
  }

  /// Runs the pipeline on [sets].
  Future<List<File>> execute(
    List<TrainingPackTemplateSet> sets, {
    String existingYamlPath = '',
    Map<String, InlineTheoryEntry> theoryIndex = const {},
    List<SkillGapCluster> clusters = const [],
    String? audience,
    Map<String, List<String>> remediationPlan = const {},
    Map<String, List<String>> theoryLinkIndex = const {},
    bool injectDryRun = false,
    int minLinksPerPack = 1,
  }) async {
    // Load existing YAMLs to prime deduplication engine.
    dashboard.start();
    await formatSelector.load();
    final appliedFormat = formatSelector.effectiveFormat(audience: audience);
    if (formatSelector.autoApply) {
      formatSelector.applyTo(generator, audience: audience);
    }
    var generatedCount = 0;
    var rejectedCount = 0;
    var totalQualityScore = 0.0;
    var processedCount = 0;
    final existingFingerprints = <PackFingerprint>[];
    final spotGen = const SpotFingerprintGenerator();
    if (remediationPlan.isNotEmpty && existingYamlPath.isNotEmpty) {
      await autoInjector.inject(
        plan: remediationPlan,
        theoryIndex: theoryLinkIndex,
        libraryDir: existingYamlPath,
        minLinksPerPack: minLinksPerPack,
        dryRun: injectDryRun,
      );
    }
    status.update(
      'pipeline',
      const AutogenStatus(isRunning: true, currentStage: 'init', progress: 0),
    );
    policyEngine.outputDir = existingYamlPath;
    await policyEngine.loadPolicies();
    if (existingYamlPath.isNotEmpty) {
      final dir = Directory(existingYamlPath);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File &&
              (entity.path.endsWith('.yaml') || entity.path.endsWith('.yml'))) {
            final yaml = await entity.readAsString();
            final tpl = TrainingPackTemplateV2.fromYaml(yaml);
            dedup.addExisting(tpl.spots);
            existingFingerprints.add(
              PackFingerprint.fromTemplate(
                tpl,
                packFingerprint: fingerprintGenerator,
                spotFingerprint: spotGen,
              ),
            );
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

        final file = await exporter.export(pack);
        files.add(file);

        dashboard.recordPack(spots.length);
        final fp = fingerprintGenerator.generateFromTemplate(pack);
        _fingerprintLog.writeln(fp);
        final pf = PackFingerprint(
          id: pack.id,
          hash: fp,
          spots: {
            for (final TrainingPackSpot s in pack.spots) spotGen.generate(s),
          },
          meta: Map<String, dynamic>.from(pack.meta),
        );
        final dupReports = packComparer.compare(pf, existingFingerprints);
        final duplicates = [
          for (final r in dupReports)
            DuplicatePackInfo(
              candidateId: pf.id,
              existingId: r.existingPackId,
              similarity: r.similarity,
              reason: r.reason.replaceAll(' ', '_'),
            ),
        ];
        await policyEngine.applyPolicies(duplicates);
        existingFingerprints.add(pf);
        status.update(
          'pipeline',
          AutogenStatus(
            isRunning: true,
            currentStage: 'template:${set.baseSpot.id}',
            progress: (i + 1) / sets.length,
          ),
        );
      }

      if (clusters.isNotEmpty) {
        boosterEngine.existingFingerprints = existingFingerprints;
        final boosters = await boosterEngine.generateBoosters(clusters);
        for (final pack in boosters) {
          final model = TrainingPackModel(
            id: pack.id,
            title: pack.name,
            spots: pack.spots,
            tags: List<String>.from(pack.tags),
            metadata: Map<String, dynamic>.from(pack.meta),
          );
          coverage.analyzePack(model);
          dashboard.recordCoverage(coverage.aggregateReport);
          final file = await exporter.export(pack);
          files.add(file);
          dashboard.recordPack(pack.spots.length);
          final fp = fingerprintGenerator.generateFromTemplate(pack);
          _fingerprintLog.writeln(fp);
          final pf = PackFingerprint(
            id: pack.id,
            hash: fp,
            spots: {
              for (final TrainingPackSpot s in pack.spots) spotGen.generate(s),
            },
            meta: Map<String, dynamic>.from(pack.meta),
          );
          final dupReports = packComparer.compare(pf, existingFingerprints);
          final duplicates = [
            for (final r in dupReports)
              DuplicatePackInfo(
                candidateId: pf.id,
                existingId: r.existingPackId,
                similarity: r.similarity,
                reason: r.reason.replaceAll(' ', '_'),
              ),
          ];
          await policyEngine.applyPolicies(duplicates);
          existingFingerprints.add(pf);
        }
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
        format: appliedFormat,
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
