import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/autogen_status.dart';
import '../models/training_pack_model.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../core/training/library/training_pack_library_v2.dart';
import 'autogen_status_dashboard_service.dart';
import 'autogen_stats_dashboard_service.dart';
import 'pack_fingerprint_comparer.dart';
import 'pack_library_service.dart';
import 'skill_tag_coverage_tracker.dart';
import 'spot_fingerprint_generator.dart';
import 'training_pack_fingerprint_generator.dart';
import 'yaml_pack_exporter.dart';

/// Request describing how to boost a training pack.
class PackBoosterRequest {
  final String packId;
  final List<String> tags;
  final double ratio;
  const PackBoosterRequest({
    required this.packId,
    required this.tags,
    required this.ratio,
  });
}

/// Provides weak-tag analytics.
abstract class TagMasteryAnalyzer {
  Future<List<String>> findWeakTags(double threshold);
}

/// Provides decayed-tag analytics.
abstract class SkillDecayTracker {
  Future<List<String>> getDecayedTags({required double threshold});
}

/// Engine detecting and boosting packs targeting weak or decayed skills.
class TargetedPackBoosterEngine {
  final TagMasteryAnalyzer? masteryAnalyzer;
  final SkillDecayTracker? decayTracker;
  final PackLibraryService library;
  final YamlPackExporter exporter;
  final AutogenStatsDashboardService dashboard;
  final SkillTagCoverageTracker coverage;

  TargetedPackBoosterEngine({
    this.masteryAnalyzer,
    this.decayTracker,
    PackLibraryService? library,
    YamlPackExporter? exporter,
    AutogenStatsDashboardService? dashboard,
    SkillTagCoverageTracker? coverage,
  })  : library = library ?? PackLibraryService.instance,
        exporter = exporter ?? const YamlPackExporter(),
        dashboard = dashboard ?? AutogenStatsDashboardService.instance,
        coverage = coverage ?? SkillTagCoverageTracker();

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
    final tags = {...weak, ...decayed};
    final requests = <PackBoosterRequest>[];
    for (final tag in tags) {
      final pack = await library.findByTag(tag);
      if (pack == null) continue;
      requests.add(PackBoosterRequest(packId: pack.id, tags: [tag], ratio: ratio));
    }
    return requests;
  }

  /// Regenerates packs with boosted coverage for [requests].
  Future<List<TrainingPackTemplateV2>> boostPacks(
      List<PackBoosterRequest> requests) async {
    final prefs = await SharedPreferences.getInstance();
    final minNovelty = prefs.getDouble('booster.minNoveltyJaccard') ?? 0.6;
    final status = AutogenStatusDashboardService.instance;
    status.update(
      'booster',
      const AutogenStatus(
        isRunning: true,
        currentStage: 'booster',
        progress: 0,
      ),
    );
    const packGen = TrainingPackFingerprintGenerator();
    const spotGen = SpotFingerprintGenerator();
    await TrainingPackLibraryV2.instance.loadFromFolder();
    final existingFingerprints = <PackFingerprint>[
      for (final p in TrainingPackLibraryV2.instance.packs)
        PackFingerprint.fromTemplate(
          p,
          packFingerprint: packGen,
          spotFingerprint: spotGen,
        ),
    ];
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
      for (var i = 0; i < addCount; i++) {
        final clone = tagged[i % tagged.length]
            .copyWith(id: const Uuid().v4());
        extra.add(clone);
      }
      final ts = DateTime.now().millisecondsSinceEpoch;
      final boosted = TrainingPackTemplateV2(
        id: '${tpl.id}_boosted_$ts',
        name: '${tpl.name}_boosted',
        trainingType: tpl.trainingType,
        spots: [...tpl.spots, ...extra],
        spotCount: tpl.spots.length + extra.length,
        tags: List<String>.from(tpl.tags),
        gameType: tpl.gameType,
        meta: {
          ...tpl.meta,
          'boostedFrom': tpl.id,
          'boostTags': req.tags,
          'boostRatio': req.ratio,
        },
      );
      final fp = PackFingerprint.fromTemplate(
        boosted,
        packFingerprint: packGen,
        spotFingerprint: spotGen,
      );
      var isDup = false;
      for (final existing in existingFingerprints) {
        final inter =
            fp.spots.intersection(existing.spots).length.toDouble();
        final union = fp.spots.union(existing.spots).length.toDouble();
        final jac = union == 0 ? 0 : inter / union;
        if (jac >= minNovelty) {
          status.recordBoosterSkipped('duplicate');
          isDup = true;
          break;
        }
      }
      if (isDup) {
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
      await exporter.export(boosted);
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
      existingFingerprints.add(fp);
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
      const AutogenStatus(
        isRunning: false,
        currentStage: 'booster',
        progress: 1,
      ),
    );
    return boostedPacks;
  }
}
