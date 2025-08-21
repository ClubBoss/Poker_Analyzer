import '../models/training_pack_model.dart';
import 'auto_deduplication_engine.dart';
import 'skill_tag_coverage_tracker.dart';

/// Selects a diverse subset of training packs for the library.
class PackLibraryAutoCuratorService {
  final AutoDeduplicationEngine _dedup;
  final SkillTagCoverageTracker? _tagTracker;
  final dynamic _clusterAnalyzer;

  PackLibraryAutoCuratorService({
    AutoDeduplicationEngine? dedup,
    SkillTagCoverageTracker? tagTracker,
    dynamic clusterAnalyzer,
  }) : _dedup = dedup ?? AutoDeduplicationEngine(),
       _tagTracker = tagTracker,
       _clusterAnalyzer = clusterAnalyzer;

  /// Filters and ranks [input], returning at most [limit] packs.
  List<TrainingPackModel> curate(
    List<TrainingPackModel> input, {
    int limit = 50,
  }) {
    if (input.isEmpty) return [];
    final deduped = _dedup.deduplicate(input);

    final bestByCluster = <String, TrainingPackModel>{};
    final others = <TrainingPackModel>[];

    for (final pack in deduped) {
      _tagTracker?.analyzePack(pack);
      final clusterId = _getClusterId(pack);
      if (clusterId != null && clusterId.isNotEmpty) {
        final existing = bestByCluster[clusterId];
        if (existing == null || _comparePacks(pack, existing) > 0) {
          bestByCluster[clusterId] = pack;
        }
      } else {
        others.add(pack);
      }
    }

    final result = <TrainingPackModel>[...bestByCluster.values, ...others];

    result.sort((a, b) {
      final count = b.spots.length.compareTo(a.spots.length);
      if (count != 0) return count;
      final tagsA = _uniqueTags(a).length;
      final tagsB = _uniqueTags(b).length;
      final tagComp = tagsB.compareTo(tagsA);
      if (tagComp != 0) return tagComp;
      return a.id.compareTo(b.id);
    });

    return result.length > limit ? result.sublist(0, limit) : result;
  }

  String? _getClusterId(TrainingPackModel pack) {
    if (_clusterAnalyzer != null) {
      try {
        final cid = _clusterAnalyzer.clusterIdFor(pack);
        if (cid is String && cid.isNotEmpty) return cid;
      } catch (_) {}
      try {
        final cid = _clusterAnalyzer.analyze(pack);
        if (cid is String && cid.isNotEmpty) return cid;
      } catch (_) {}
    }
    final metaCluster =
        pack.metadata['clusterId'] ??
        pack.metadata['theoryClusterId'] ??
        pack.metadata['cluster'];
    if (metaCluster is String && metaCluster.trim().isNotEmpty) {
      return metaCluster.trim();
    }
    for (final spot in pack.spots) {
      final m = spot.meta;
      final c =
          m['cluster'] ??
          m['theoryCluster'] ??
          m['clusterId'] ??
          m['theoryClusterId'];
      if (c is String && c.trim().isNotEmpty) return c.trim();
    }
    return null;
  }

  int _comparePacks(TrainingPackModel a, TrainingPackModel b) {
    final bySpots = a.spots.length.compareTo(b.spots.length);
    if (bySpots != 0) return bySpots;
    final ta = _uniqueTags(a).length;
    final tb = _uniqueTags(b).length;
    return ta.compareTo(tb);
  }

  Set<String> _uniqueTags(TrainingPackModel pack) {
    final tags = <String>{};
    for (final t in pack.tags) {
      final v = t.trim().toLowerCase();
      if (v.isNotEmpty) tags.add(v);
    }
    for (final s in pack.spots) {
      for (final t in s.tags) {
        final v = t.trim().toLowerCase();
        if (v.isNotEmpty) tags.add(v);
      }
    }
    return tags;
  }
}
