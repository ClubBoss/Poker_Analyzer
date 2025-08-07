import 'package:shared_preferences/shared_preferences.dart';

import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'pack_library_service.dart';
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

  TargetedPackBoosterEngine({
    this.masteryAnalyzer,
    this.decayTracker,
    PackLibraryService? library,
    YamlPackExporter? exporter,
  })  : library = library ?? PackLibraryService.instance,
        exporter = exporter ?? const YamlPackExporter();

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
  Future<void> boostPacks(List<PackBoosterRequest> requests) async {
    for (final req in requests) {
      final tpl = await library.getById(req.packId);
      if (tpl == null) continue;
      final tagged = tpl.spots
          .where((s) => s.tags.any((t) => req.tags.contains(t)))
          .toList();
      if (tagged.isEmpty) continue;
      final addCount = (tagged.length * (req.ratio - 1)).round();
      final extra = <TrainingPackSpot>[];
      for (var i = 0; i < addCount; i++) {
        extra.add(tagged[i % tagged.length]);
      }
      final boosted = TrainingPackTemplateV2(
        id: '${tpl.id}_boosted',
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
      await exporter.export(boosted);
    }
  }
}
