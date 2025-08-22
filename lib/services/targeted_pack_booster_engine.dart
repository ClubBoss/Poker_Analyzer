import 'dart:async';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/autogen_status.dart';
import '../models/training_pack_model.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'autogen_status_dashboard_service.dart';
import 'autogen_stats_dashboard_service.dart';
import 'pack_library_service.dart';
import 'auto_skill_gap_clusterer.dart';
import 'skill_tag_coverage_tracker.dart';
import 'yaml_pack_exporter.dart';
import 'pack_novelty_guard_service.dart';

/// Request describing how to boost a training pack.
class PackBoosterRequest {
  final String packId;
  final List<String> tags;
  final double ratio;
  final String triggerReason;
  PackBoosterRequest({
    required this.packId,
    required this.tags,
    required this.ratio,
    required this.triggerReason,
  });
}

/// Provides weak-tag analytics.
abstract class TagMasteryAnalyzer {
  Future<List<String>> findWeakTags(double threshold);
}

/// Provides decayed-tag analytics.
abstract class SkillDecayTracker {
  Future<List<String>> getDecayedTags({required double threshold});
  Stream<String> get onDecayStateChanged;
}

/// Engine detecting and boosting packs targeting weak or decayed skills.
class TargetedPackBoosterEngine {
  final TagMasteryAnalyzer? masteryAnalyzer;
  final SkillDecayTracker? decayTracker;
  final PackLibraryService library;
  final YamlPackExporter exporter;
  final AutogenStatsDashboardService dashboard;
  final SkillTagCoverageTracker coverage;
  final PackNoveltyGuardService noveltyGuard;
  final Duration decayDebounce;
  final Set<String> _pendingDecayTags = {};
  Timer? _decayTimer;

  TargetedPackBoosterEngine({
    this.masteryAnalyzer,
    this.decayTracker,
    PackLibraryService? library,
    YamlPackExporter? exporter,
    AutogenStatsDashboardService? dashboard,
    SkillTagCoverageTracker? coverage,
    PackNoveltyGuardService? noveltyGuard,
    Duration decayDebounce = const Duration(seconds: 2),
  }) : library = library ?? PackLibraryService.instance,
       exporter = exporter ?? const YamlPackExporter(),
       dashboard = dashboard ?? AutogenStatsDashboardService.instance,
       coverage = coverage ?? SkillTagCoverageTracker(),
       noveltyGuard = noveltyGuard ?? PackNoveltyGuardService(),
       decayDebounce = decayDebounce {
    if (decayTracker != null) {
      decayTracker!.onDecayStateChanged.listen(_handleDecayEvent);
    }
  }

  /// Scans analytics services for weak or decayed tags and returns
  /// matching pack boost requests.
  Future<List<PackBoosterRequest>> detectBoostCandidates() async {
    final prefs = await SharedPreferences.getInstance();
    final threshold = prefs.getDouble('booster.threshold') ?? 0.75;
    final ratio = prefs.getDouble('booster.ratio') ?? 1.5;
    final weak = masteryAnalyzer == null
        ? <String>[]
        : await masteryAnalyzer!.findWeakTags(threshold);
    final decayed = decayTracker == null
        ? <String>[]
        : await decayTracker!.getDecayedTags(threshold: threshold);
    final tagReasons = <String, String>{};
    for (final t in weak) {
      tagReasons[t] = 'lowMastery';
    }
    for (final t in decayed) {
      tagReasons[t] = 'decayThreshold';
    }
    final requests = <PackBoosterRequest>[];
    for (final tag in tagReasons.keys) {
      final pack = await library.findByTag(tag);
      if (pack == null) continue;
      requests.add(
        PackBoosterRequest(
          packId: pack.id,
          tags: [tag],
          ratio: ratio,
          triggerReason: tagReasons[tag]!,
        ),
      );
    }
    return requests;
  }

  /// Manually trigger booster generation for [tags].
  Future<List<TrainingPackTemplateV2>> generateBoosterPacks({
    required int count,
    required List<String> tags,
    String triggerReason = 'manual',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final ratio = prefs.getDouble('booster.ratio') ?? 1.5;
    final requests = <PackBoosterRequest>[];
    for (final tag in tags.take(count)) {
      final pack = await library.findByTag(tag);
      if (pack == null) continue;
      requests.add(
        PackBoosterRequest(
          packId: pack.id,
          tags: [tag],
          ratio: ratio,
          triggerReason: triggerReason,
        ),
      );
    }
    if (requests.isEmpty) return [];
    return boostPacks(requests);
  }

  /// Generates boosters that target multiple related tags per cluster.
  Future<List<TrainingPackTemplateV2>> generateClusterBoosterPacks({
    required List<SkillTagCluster> clusters,
    String triggerReason = 'cluster',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final ratio = prefs.getDouble('booster.ratio') ?? 1.5;
    final requests = <PackBoosterRequest>[];
    for (final cluster in clusters) {
      if (cluster.tags.isEmpty) continue;
      final pack = await library.findByTag(cluster.tags.first);
      if (pack == null) continue;
      if (!cluster.tags.every(pack.tags.contains)) continue;
      requests.add(
        PackBoosterRequest(
          packId: pack.id,
          tags: cluster.tags,
          ratio: ratio,
          triggerReason: triggerReason,
        ),
      );
    }
    return boostPacks(requests);
  }

  void _handleDecayEvent(String tag) {
    _pendingDecayTags.add(tag);
    _decayTimer?.cancel();
    _decayTimer = Timer(decayDebounce, () {
      _processDecayTags();
    });
  }

  Future<void> _processDecayTags() async {
    if (decayTracker == null) return;
    final tags = List<String>.from(_pendingDecayTags);
    _pendingDecayTags.clear();
    if (tags.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final threshold = prefs.getDouble('booster.threshold') ?? 0.75;
    final decayed = await decayTracker!.getDecayedTags(threshold: threshold);
    final unique = await _filterRecentDuplicates(
      tags.where((t) => decayed.contains(t)).toList(),
    );
    if (unique.isEmpty) return;
    final status = AutogenStatusDashboardService.instance;
    status.update(
      'booster',
      AutogenStatus(isRunning: true, currentStage: 'decaySync', progress: 0),
    );
    await generateBoosterPacks(
      count: unique.length,
      tags: unique,
      triggerReason: 'decaySync',
    );
    status.update(
      'booster',
      AutogenStatus(isRunning: false, currentStage: 'decaySync', progress: 1),
    );
  }

  Future<List<String>> _filterRecentDuplicates(List<String> tags) async {
    final dir = Directory('boosterPacks');
    if (!dir.existsSync()) return tags;
    final cutoff = DateTime.now().subtract(const Duration(hours: 24));
    final recent = <String>{};
    for (final entity in dir.listSync().whereType<File>()) {
      if (!entity.path.endsWith('.yaml')) continue;
      try {
        final yaml = await entity.readAsString();
        final tpl = TrainingPackTemplateV2.fromYamlAuto(yaml);
        final gen = tpl.meta['generatedAt']?.toString();
        final ts = gen != null ? DateTime.tryParse(gen) : null;
        if (ts == null || ts.isBefore(cutoff)) continue;
        final targeted =
            (tpl.meta['tagsTargeted'] as List?)?.map((e) => e.toString()) ?? [];
        for (final t in targeted) {
          recent.add(t.toLowerCase());
        }
      } catch (_) {}
    }
    final unique = <String>[];
    for (final t in tags) {
      if (recent.contains(t.toLowerCase())) {
        AutogenStatusDashboardService.instance.recordBoosterSkipped(
          'recent_duplicate',
        );
      } else {
        unique.add(t);
      }
    }
    return unique;
  }

  /// Regenerates packs with boosted coverage for [requests].
  Future<List<TrainingPackTemplateV2>> boostPacks(
    List<PackBoosterRequest> requests,
  ) async {
    final status = AutogenStatusDashboardService.instance;
    status.update(
      'booster',
      AutogenStatus(isRunning: true, currentStage: 'booster', progress: 0),
    );
    final boostedPacks = <TrainingPackTemplateV2>[];
    for (var i = 0; i < requests.length; i++) {
      final req = requests[i];
      final tpl = await library.getById(req.packId);
      if (tpl == null) {
        status.update(
          'booster',
          AutogenStatus(
            isRunning: true,
            currentStage: 'booster',
            progress: (i + 1) / requests.length,
          ),
        );
        continue;
      }
      final tagged = tpl.spots
          .where((s) => s.tags.any((t) => req.tags.contains(t)))
          .toList();
      if (tagged.isEmpty) {
        status.recordBoosterSkipped('no_tagged_spots');
        status.update(
          'booster',
          AutogenStatus(
            isRunning: true,
            currentStage: 'booster',
            progress: (i + 1) / requests.length,
          ),
        );
        continue;
      }
      final addCount = (tagged.length * (req.ratio - 1)).round();
      final extra = <TrainingPackSpot>[];
      for (var j = 0; j < addCount; j++) {
        final clone = tagged[j % tagged.length].copyWith(id: const Uuid().v4());
        extra.add(clone);
      }
      final spots = [for (final s in tagged) s, ...extra];
      final ts = DateTime.now().millisecondsSinceEpoch;
      final boosted = TrainingPackTemplateV2(
        id: '${tpl.id}_boosted_$ts',
        name: '${tpl.name}_boosted',
        trainingType: tpl.trainingType,
        spots: spots,
        spotCount: spots.length,
        tags: List<String>.from(req.tags),
        gameType: tpl.gameType,
        meta: {
          ...tpl.meta,
          'type': 'booster',
          'sourcePack': tpl.id,
          'tagsTargeted': req.tags,
          'generatedAt': DateTime.now().toIso8601String(),
          'triggerReason': req.triggerReason,
        },
      );
      final novelty = await noveltyGuard.evaluate(boosted);
      if (novelty.isDuplicate) {
        status.recordBoosterSkipped('duplicate');
        status.update(
          'booster',
          AutogenStatus(
            isRunning: true,
            currentStage: 'booster',
            progress: (i + 1) / requests.length,
          ),
        );
        continue;
      }
      final exported = await exporter.export(boosted);
      final boosterDir = Directory('boosterPacks');
      await boosterDir.create(recursive: true);
      final fileName = exported.uri.pathSegments.last;
      await exported.copy('${boosterDir.path}/$fileName');
      status.recordBoosterGenerated(boosted.id);
      dashboard.recordPack(boosted.spotCount);
      final model = TrainingPackModel(
        id: boosted.id,
        title: boosted.name,
        spots: boosted.spots,
        tags: List<String>.from(boosted.tags),
        metadata: Map<String, dynamic>.from(boosted.meta),
      );
      coverage.analyzePack(model);
      dashboard.recordCoverage(coverage.aggregateReport);
      await noveltyGuard.registerExport(boosted);
      boostedPacks.add(boosted);
      status.update(
        'booster',
        AutogenStatus(
          isRunning: true,
          currentStage: 'booster',
          progress: (i + 1) / requests.length,
        ),
      );
    }
    status.update(
      'booster',
      AutogenStatus(isRunning: false, currentStage: 'booster', progress: 1),
    );
    return boostedPacks;
  }
}
