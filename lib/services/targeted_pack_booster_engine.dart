import 'package:shared_preferences/shared_preferences.dart';

import '../core/training/library/training_pack_library_v2.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import '../models/game_type.dart';
import 'board_texture_classifier.dart';
import 'spot_fingerprint_generator.dart';
import 'training_pack_fingerprint_generator.dart';
import 'pack_fingerprint_comparer.dart';
import 'autogen_status_dashboard_service.dart';
import 'auto_skill_gap_clusterer.dart';

/// Builds targeted booster packs for clusters of weak skills.
class TargetedPackBoosterEngine {
  TargetedPackBoosterEngine({
    TrainingPackLibraryV2? library,
    BoardTextureClassifier? boardClassifier,
    SpotFingerprintGenerator? spotFingerprint,
    PackFingerprintComparer? comparer,
    Future<SharedPreferences> Function()? prefs,
  })  : _library = library ?? TrainingPackLibraryV2.instance,
        _boardClassifier = boardClassifier ?? const BoardTextureClassifier(),
        _spotGen = spotFingerprint ?? const SpotFingerprintGenerator(),
        _packGen = const TrainingPackFingerprintGenerator(),
        _comparer = comparer ?? const PackFingerprintComparer(),
        _prefs = prefs ?? SharedPreferences.getInstance;

  final TrainingPackLibraryV2 _library;
  final BoardTextureClassifier _boardClassifier;
  final SpotFingerprintGenerator _spotGen;
  final TrainingPackFingerprintGenerator _packGen;
  final PackFingerprintComparer _comparer;
  final Future<SharedPreferences> Function() _prefs;

  /// Existing pack fingerprints used for novelty checks.
  List<PackFingerprint> existingFingerprints = [];

  /// Generates booster packs targeting [clusters].
  Future<List<TrainingPackTemplateV2>> generateBoosters(
    List<SkillGapCluster> clusters, {
    int maxPacks = 3,
    int spotsPerPack = 12,
  }) async {
    if (clusters.isEmpty) return [];
    final prefs = await _prefs();
    final max = prefs.getInt('booster.maxPacks') ?? maxPacks;
    final perPack = prefs.getInt('booster.spotsPerPack') ?? spotsPerPack;
    final minNovelty =
        prefs.getDouble('booster.minNoveltyJaccard') ?? 0.6;

    final result = <TrainingPackTemplateV2>[];
    final status = AutogenStatusDashboardService.instance;

    for (final cluster in clusters.take(max)) {
      // Collect candidate spots by tags.
      final candidates = <TrainingPackSpot>[];
      for (final p in _library.packs) {
        for (final s in p.spots) {
          if (s.tags.any((t) => cluster.tags.contains(t))) {
            candidates.add(s);
          }
        }
      }
      if (candidates.isEmpty) {
        status.recordBoosterSkipped('no_spots');
        continue;
      }

      final selected = <TrainingPackSpot>[];
      final textures = <String>{};
      for (final s in candidates) {
        if (selected.length >= perPack) break;
        final texture = _boardClassifier.classify(s.board.join('')).join(',');
        if (textures.add(texture)) {
          selected.add(s);
        }
      }
      for (final s in candidates) {
        if (selected.length >= perPack) break;
        if (!selected.contains(s)) selected.add(s);
      }

      if (selected.isEmpty) {
        status.recordBoosterSkipped('no_spots');
        continue;
      }

      final pack = TrainingPackTemplateV2(
        id: 'booster_${cluster.clusterName}_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Booster — ${cluster.clusterName}',
        trainingType: TrainingType.custom,
        spots: selected,
        spotCount: selected.length,
        tags: [...cluster.tags, 'booster'],
        gameType: GameType.cash,
        meta: {
          'source': 'booster',
          'cluster': cluster.clusterName,
          'tags': cluster.tags,
        },
      );

      final fp = PackFingerprint.fromTemplate(
        pack,
        packFingerprint: _packGen,
        spotFingerprint: _spotGen,
      );
      var novel = true;
      for (final e in existingFingerprints) {
        final inter = fp.spots.intersection(e.spots).length.toDouble();
        final union = fp.spots.union(e.spots).length.toDouble();
        final jaccard = union == 0 ? 0 : inter / union;
        if (jaccard >= minNovelty) {
          novel = false;
          break;
        }
      }
      if (!novel) {
        status.recordBoosterSkipped('duplicate');
        continue;
      }
      existingFingerprints.add(fp);
      result.add(pack);
      status.recordBoosterGenerated(pack.id);
    }
    return result;
  }
}
