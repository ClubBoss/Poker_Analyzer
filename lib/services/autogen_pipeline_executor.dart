import 'dart:io';
import 'dart:convert';
import 'dart:async';

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
import 'skill_tag_coverage_guard_service.dart';
import '../models/coverage_report.dart';
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
import 'ab_orchestrator_service.dart';
import '../models/texture_filter_config.dart';

/// Centralized orchestrator running the full auto-generation pipeline.
class AutogenPipelineExecutor {
  late final TrainingPackAutoGenerator generator;
  final AutoDeduplicationEngine dedup;
  final YamlPackExporter exporter;
  final SkillTagCoverageTracker coverage;
  final SkillTagCoverageGuardService coverageGuard;
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
  final TextureFilterConfig? textureFilters;
  final String? presetId;
  final String? presetName;
  final StreamController<AutogenStatus> _statusController =
      StreamController.broadcast();

  Stream<AutogenStatus> get status$ => _statusController.stream;

  AutogenPipelineExecutor({
    TrainingPackAutoGenerator? generator,
    AutoDeduplicationEngine? dedup,
    YamlPackExporter? exporter,
    SkillTagCoverageTracker? coverage,
    SkillTagCoverageGuardService? coverageGuard,
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
    TextureFilterConfig? textureFilters,
    String? presetId,
    String? presetName,
  })  : dedup = dedup ?? AutoDeduplicationEngine(),
        exporter = exporter ?? const YamlPackExporter(),
        coverage = coverage ?? SkillTagCoverageTracker(),
        coverageGuard = coverageGuard ??
            SkillTagCoverageGuardService.fromEnv() ??
            SkillTagCoverageGuardService(),
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
        autoInjector = autoInjector ?? TheoryAutoInjector(),
        noveltyGuard = noveltyGuard ?? PackNoveltyGuardService(),
        failOnSeedErrors =
            failOnSeedErrors ?? (Platform.environment['CI'] == 'true'),
        textureFilters = textureFilters,
        presetId = presetId,
        presetName = presetName {
    this.generator = generator ??
        TrainingPackAutoGenerator(
          dedup: this.dedup,
          boardClassifier: boardClassifier,
          textureFilters: textureFilters,
        );
    if (generator != null) {
      generator.textureFilters = textureFilters;
    }
  }

  void _emitStatus(AutogenStatus status) {
    _statusController.add(status);
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
    status.resetCoverageMetrics();
    await formatSelector.load();
    final appliedFormat = formatSelector.effectiveFormat(audience: audience);
    if (formatSelector.autoApply) {
      formatSelector.applyTo(generator, audience: audience);
    }
    var generatedCount = 0;
    var rejectedCount = 0;
    var totalQualityScore = 0.0;
    var processedCount = 0;
    final startedAt = DateTime.now();
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
    _emitStatus(
      AutogenStatus(
        state: AutogenRunState.running,
        currentStep: 'init',
        queueDepth: sets.length,
        processed: 0,
        errorsCount: 0,
        startedAt: startedAt,
        updatedAt: DateTime.now(),
      ),
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
      dashboard.setTargetTextureMix(textureFilters?.targetMix ?? {});
      for (var i = 0; i < sets.length; i++) {
        final set = sets[i];
        _emitStatus(
          AutogenStatus(
            state: AutogenRunState.running,
            currentStep: 'template:${set.baseSpot.id}',
            queueDepth: sets.length - i,
            processed: i,
            errorsCount: 0,
            startedAt: startedAt,
            updatedAt: DateTime.now(),
          ),
        );
        if (generator.shouldAbort) break;
        var spots = await generator.generate(set, theoryIndex: theoryIndex);
        if (generator.shouldAbort) break;
        if (spots.isEmpty) {
          _emitStatus(
            AutogenStatus(
              state: AutogenRunState.running,
              currentStep: 'template:${set.baseSpot.id}',
              queueDepth: sets.length - (i + 1),
              processed: i + 1,
              errorsCount: 0,
              startedAt: startedAt,
              updatedAt: DateTime.now(),
            ),
          );
          continue;
        }
        AutogenPipelineDebugStatsService.incrementGenerated();
        AutogenPipelineEventLoggerService.log(
          'generated',
          'Generated ${spots.length} spots for template ${set.baseSpot.id}',
        );

        final theorySummary = theoryInjector.injectAll(spots, theoryIndex);
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
        pack.meta['autogenMeta'] = {
          if (presetId != null) 'presetId': presetId,
          if (presetName != null) 'presetName': presetName,
          if (textureFilters != null)
            'textureFilters': textureFilters!.toJson(),
          'textureDistribution': dashboard.textureCounts,
          'theorySummary': theorySummary.toJson(),
        };

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
        final CoverageReport cov = await coverageGuard.evaluate(pack);
        status.recordCoverageEval(cov.coveragePct, rejected: !cov.passes);
        if (!cov.passes) {
          rejectedCount++;
          AutogenPipelineEventLoggerService.log(
            'coverage.reject',
            'Pack ${pack.id} coverage ${cov.coveragePct.toStringAsFixed(2)}',
          );
          _emitStatus(
            AutogenStatus(
              state: AutogenRunState.running,
              currentStep: 'template:${set.baseSpot.id}',
              queueDepth: sets.length - (i + 1),
              processed: i + 1,
              errorsCount: 0,
              startedAt: startedAt,
              updatedAt: DateTime.now(),
            ),
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
        _emitStatus(
          AutogenStatus(
            state: AutogenRunState.running,
            currentStep: 'template:${set.baseSpot.id}',
            queueDepth: sets.length - (i + 1),
            processed: i + 1,
            errorsCount: 0,
            startedAt: startedAt,
            updatedAt: DateTime.now(),
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
        final CoverageReport cov = await coverageGuard.evaluate(pack);
        status.recordCoverageEval(cov.coveragePct, rejected: !cov.passes);
        if (!cov.passes) {
          AutogenPipelineEventLoggerService.log(
            'coverage.reject',
            'Boosted pack ${pack.id} coverage ${cov.coveragePct.toStringAsFixed(2)}',
          );
          continue;
        }
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
      final avgQuality =
          processedCount == 0 ? 0.0 : totalQualityScore / processedCount;
      await runHistory.logRun(
        generated: generatedCount,
        rejected: rejectedCount,
        avgScore: avgQuality,
        format: appliedFormat,
      );
      await TheoryInjectionSchedulerService.instance.runNow(force: true);
      _emitStatus(
        AutogenStatus(
          state: AutogenRunState.idle,
          currentStep: 'complete',
          queueDepth: 0,
          processed: processedCount,
          errorsCount: 0,
          startedAt: startedAt,
          updatedAt: DateTime.now(),
        ),
      );
      return files;
    } catch (e) {
      _emitStatus(
        AutogenStatus(
          state: AutogenRunState.idle,
          currentStep: 'error',
          queueDepth: 0,
          processed: processedCount,
          errorsCount: 1,
          startedAt: startedAt,
          updatedAt: DateTime.now(),
          lastErrorMsg: e.toString(),
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
    var aud = audience ?? 'regular';
    var fmt = format ?? 'standard';
    final abSvc = ABOrchestratorService.instance;
    final arms = await abSvc.resolveActiveArms(userId, aud);
    for (final arm in arms) {
      if (arm.audience != null) aud = arm.audience!;
      if (arm.format != null) fmt = arm.format!;
      abSvc.logExposure(
        userId,
        arm.expId,
        arm.armId,
        audience: aud,
        format: fmt,
      );
    }
    final abStr = arms.map((a) => '${a.expId}:${a.armId}').join(',');
    final overridesApplied = arms.any((a) => a.prefs.isNotEmpty);

    Future<List<File>> core() async {
      final planner = AdaptiveTrainingPlanner();
      final plan = await planner.plan(
        userId: userId,
        durationMinutes: durationMinutes,
        audience: aud,
        format: fmt,
        abArm: abStr.isEmpty ? null : abStr,
      );
      final sig = await PlanSignatureBuilder().build(
        userId: userId,
        plan: plan,
        audience: aud,
        format: fmt,
        budgetMinutes: durationMinutes,
        abArm: abStr.isEmpty ? null : abStr,
      );

      final exec = executor ?? const AdaptivePlanExecutor();
      final store = exec.store;
      final lock = PathWriteLockService(rootDir: store.rootDir);
      final txn = PathTransactionManager(rootDir: store.rootDir);
      final guard = PlanIdempotencyGuard();
      final prefs = await SharedPreferences.getInstance();
      final windowHours = prefs.getInt('planner.idempotency.windowHours') ?? 24;
      final start = DateTime.now();
      final acquired = await lock.acquire(userId);
      final assignment = abStr.isEmpty ? 'none' : abStr;
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
              if (abStr.isNotEmpty) 'abArm': abStr,
              'assignment': assignment,
              'overridesApplied': overridesApplied,
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
          await PathTransactionManager(rootDir: '.').rollbackFileBackups();
          AutogenStatusDashboardService.instance.update(
            'PathHardening',
            AutogenStatus(
              isRunning: false,
              currentStage: jsonEncode({
                'userId': userId,
                'sig': sig,
                'action': 'skip',
                'createdModules': 0,
                'durationMs': DateTime.now().difference(start).inMilliseconds,
                if (abStr.isNotEmpty) 'abArm': abStr,
                'assignment': assignment,
                'overridesApplied': overridesApplied,
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
          abArm: abStr.isEmpty ? null : abStr,
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
              'durationMs': DateTime.now().difference(start).inMilliseconds,
              if (abStr.isNotEmpty) 'abArm': abStr,
              'assignment': assignment,
              'overridesApplied': overridesApplied,
            }),
          ),
        );
        return <File>[];
      } catch (e) {
        await txn.rollback(userId, txId);
        await PathTransactionManager(rootDir: '.').rollbackFileBackups();
        AutogenStatusDashboardService.instance.update(
          'PathHardening',
          AutogenStatus(
            isRunning: false,
            currentStage: jsonEncode({
              'userId': userId,
              'sig': sig,
              'action': 'rollback',
              'createdModules': 0,
              'durationMs': DateTime.now().difference(start).inMilliseconds,
              if (abStr.isNotEmpty) 'abArm': abStr,
              'assignment': assignment,
              'overridesApplied': overridesApplied,
            }),
            lastError: e.toString(),
          ),
        );
        rethrow;
      } finally {
        await lock.release(userId);
      }
    }

    Future<List<File>> wrap(int idx) {
      if (idx >= arms.length) return core();
      return abSvc.withOverrides(arms[idx], () => wrap(idx + 1));
    }

    return await wrap(0);
  }
}
