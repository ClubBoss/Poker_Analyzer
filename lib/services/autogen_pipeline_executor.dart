import 'dart:io';
import 'dart:convert';

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
import '../core/models/spot_seed/spot_seed_codec.dart';
import '../core/models/spot_seed/spot_seed_validator.dart';
import '../core/models/spot_seed/legacy_seed_adapter.dart';
import '../core/models/spot_seed/seed_issue.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pack_novelty_guard_service.dart';
import 'theory_injection_scheduler_service.dart';
import 'adaptive_training_planner.dart';
import 'adaptive_plan_executor.dart';
import 'plan_signature_builder.dart';
import 'plan_idempotency_guard.dart';
import 'path_write_lock_service.dart';
import 'path_transaction_manager.dart';
import 'learning_path_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final PackNoveltyGuardService noveltyGuard;
  final bool failOnSeedErrors;

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
    PackNoveltyGuardService? noveltyGuard,
    bool? failOnSeedErrors,
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
       status = status ?? AutogenStatusDashboardService(),
       icmInjector = icmInjector,
       gatekeeper = gatekeeper ?? const PackQualityGatekeeperService(),
       runHistory = runHistory ?? const AutogenRunHistoryLoggerService(),
       packComparer = packComparer ?? const PackFingerprintComparer(),
       policyEngine = policyEngine ?? DeduplicationPolicyEngine(),
       boosterEngine = boosterEngine ?? TargetedPackBoosterEngine(),
       formatSelector = formatSelector ?? AutoFormatSelector(),
       autoInjector = autoInjector ?? TheoryAutoInjector(),
       noveltyGuard = noveltyGuard ?? PackNoveltyGuardService(),
       failOnSeedErrors =
           failOnSeedErrors ?? (Platform.environment['CI'] == 'true') {
    this.generator = generator ?? TrainingPackAutoGenerator(dedup: this.dedup);
  }

  /// Convert and validate raw seed inputs using USF. Legacy formats are
  /// auto-detected and adapted via [LegacySeedAdapter]. Issues are reported to
  /// [AutogenStatusDashboardService.seedIssuesNotifier].
  Future<List<SpotSeed>> _ingestSeeds(List<dynamic> raw) async {
    final prefs = await SharedPreferences.getInstance();
    final validator = SpotSeedValidator(
      preferences: SpotSeedValidatorPreferences(
        allowUnknownTags: prefs.getBool('usf.allowUnknownTags') ?? true,
        maxComboCount: prefs.getInt('usf.maxComboCount'),
        requireRangesForStreets:
            prefs.getStringList('usf.requireRangesForStreets') ?? const [],
        validateBoardLength: prefs.getBool('usf.validateBoardLength') ?? false,
        validatePositionConsistency:
            prefs.getBool('usf.validatePositionConsistency') ?? false,
      ),
    );
    const adapter = LegacySeedAdapter();
    final seeds = <SpotSeed>[];
    final allIssues = <SeedIssue>[];
    for (final item in raw) {
      SpotSeed seed;
      if (item is SpotSeed) {
        seed = item;
      } else if (item is Map<String, dynamic>) {
        seed = adapter.convert(item);
      } else {
        continue;
      }
      final issues = validator
          .validate(seed)
          .map(
            (i) => SeedIssue(
              code: i.code,
              severity: i.severity,
              message: i.message,
              path: i.path,
              seedId: seed.id,
            ),
          )
          .toList();
      if (issues.isNotEmpty) {
        AutogenStatusDashboardService.instance.reportSeedIssues(
          seed.id,
          issues,
        );
        allIssues.addAll(issues);
      }
      seeds.add(seed);
    }
    final errors = allIssues.where((i) => i.severity == 'error').toList();
    if (errors.isNotEmpty && failOnSeedErrors) {
      final buffer = StringBuffer(
        'ERROR: Seed validation failed (${errors.length} errors)',
      );
      for (final e in errors) {
        buffer.writeln('\n- seedId=${e.seedId ?? ''}, issue=${e.code}');
      }
      stderr.writeln(buffer.toString());
      throw Exception('seed_validation_failed');
    }
    return seeds;
  }

  /// Runs the pipeline on [sets].
  ///
  /// Returns the list of files exported for the primary generation step.
  /// Boosted packs are exported separately and are not included in the
  /// returned collection.
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
          model = await icmInjector!.inject(model);
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
        final novelty = await noveltyGuard.evaluate(pack);
        if (novelty.isDuplicate) {
          status.recordBoosterSkipped('duplicate');
          status.flagDuplicate(
            pack.id,
            novelty.bestMatchId ?? '',
            'novelty',
            novelty.jaccard,
          );
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
        await noveltyGuard.registerExport(pack);
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
      final boostRequests = await boosterEngine.detectBoostCandidates();
      final boosted = boostRequests.isNotEmpty
          ? await boosterEngine.boostPacks(boostRequests)
          : <TrainingPackTemplateV2>[];
      for (final pack in boosted) {
        final model = TrainingPackModel(
          id: pack.id,
          title: pack.name,
          spots: pack.spots,
          tags: List<String>.from(pack.tags),
          metadata: Map<String, dynamic>.from(pack.meta),
        );
        coverage.analyzePack(model);
        dashboard.recordCoverage(coverage.aggregateReport);
        dashboard.recordPack(pack.spots.length);
        final fpHash = fingerprintGenerator.generateFromTemplate(pack);
        _fingerprintLog.writeln(fpHash);
        final pf = PackFingerprint(
          id: pack.id,
          hash: fpHash,
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
      await coverage.logSummary();
      await _fingerprintLog.flush();
      await _fingerprintLog.close();
      await dashboard.logFinalStats(
        coverage.aggregateReport,
        yamlFiles: files.length + boosted.length,
      );
      final avgQuality = processedCount == 0
          ? 0.0
          : totalQualityScore / processedCount;
      await runHistory.logRun(
        generated: generatedCount,
        rejected: rejectedCount,
        avgScore: avgQuality,
        format: appliedFormat,
      );
      await TheoryInjectionSchedulerService.instance.runNow(force: true);
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

  Future<List<File>> planAndInjectForUser(
    String userId, {
    required int durationMinutes,
    String? audience,
    String? format,
    AdaptivePlanExecutor? executor,
  }) async {
    final planner = AdaptiveTrainingPlanner();
    final plan = await planner.plan(
      userId: userId,
      durationMinutes: durationMinutes,
      audience: audience ?? 'regular',
      format: format ?? 'standard',
    );
    final sig = await PlanSignatureBuilder().build(
      userId: userId,
      plan: plan,
      audience: audience ?? 'regular',
      format: format ?? 'standard',
      budgetMinutes: durationMinutes,
    );

    final exec = executor ?? const AdaptivePlanExecutor();
    final store = exec.store;
    final lock = PathWriteLockService(rootDir: store.rootDir);
    final txn = PathTransactionManager(rootDir: store.rootDir);
    final guard = PlanIdempotencyGuard();
    final prefs = await SharedPreferences.getInstance();
    final windowHours =
        prefs.getInt('planner.idempotency.windowHours') ?? 24;
    final start = DateTime.now();
    final acquired = await lock.acquire(userId);
    if (!acquired) {
      AutogenStatusDashboardService.instance.update(
        'PathHardening',
        AutogenStatus(
          isRunning: false,
          currentStage: jsonEncode({
            'userId': userId,
            'sig': sig,
            'action': 'locked',
            'createdModules': 0,
            'durationMs': 0,
          }),
        ),
      );
      return <File>[];
    }
    String txId = '';
    try {
      await txn.reconcile(userId);
      txId = await txn.begin(userId, sig);
      final should = await guard.shouldInject(
        userId,
        sig,
        window: Duration(hours: windowHours),
      );
      if (!should) {
        await txn.rollback(userId, txId);
        AutogenStatusDashboardService.instance.update(
          'PathHardening',
          AutogenStatus(
            isRunning: false,
            currentStage: jsonEncode({
              'userId': userId,
              'sig': sig,
              'action': 'skip',
              'createdModules': 0,
              'durationMs':
                  DateTime.now().difference(start).inMilliseconds,
            }),
          ),
        );
        return <File>[];
      }
      final modules = await exec.execute(
        userId: userId,
        plan: plan,
        budgetMinutes: durationMinutes,
        sig: sig,
      );
      for (final m in modules) {
        await txn.recordModule(userId, txId, m.moduleId);
      }
      await txn.commit(userId, txId);
      await guard.recordInjected(userId, sig);
      await TheoryInjectionSchedulerService.instance.runNow(force: true);
      AutogenStatusDashboardService.instance.update(
        'PathHardening',
        AutogenStatus(
          isRunning: false,
          currentStage: jsonEncode({
            'userId': userId,
            'sig': sig,
            'action': 'inject',
            'createdModules': modules.length,
            'durationMs':
                DateTime.now().difference(start).inMilliseconds,
          }),
        ),
      );
      return <File>[];
    } catch (e) {
      await txn.rollback(userId, txId);
      AutogenStatusDashboardService.instance.update(
        'PathHardening',
        AutogenStatus(
          isRunning: false,
          currentStage: jsonEncode({
            'userId': userId,
            'sig': sig,
            'action': 'rollback',
            'createdModules': 0,
            'durationMs':
                DateTime.now().difference(start).inMilliseconds,
          }),
          lastError: e.toString(),
        ),
      );
      rethrow;
    } finally {
      await lock.release(userId);
    }
  }
}
