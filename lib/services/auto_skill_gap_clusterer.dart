import 'dart:math';

/// Cluster of related skill tags that represent a broader weakness theme.
class SkillTagCluster {
  final List<String> tags;
  final String clusterId;
  final String themeName;

  const SkillTagCluster({
    required this.tags,
    required this.clusterId,
    required this.themeName,
  });
}

/// Automatically groups weak or decayed skill tags into thematic clusters
/// based on tag co-occurrence across training spots.
class AutoSkillGapClusterer {
  /// Minimum percentage of overlap required to link two tags.
  final double linkPercentage;

  /// Maximum tags per cluster.
  final int maxClusterSize;

  /// Optional mapping from tag -> human friendly theme name.
  final Map<String, String> themeMap;

  const AutoSkillGapClusterer({
    this.linkPercentage = 0.5,
    this.maxClusterSize = 5,
    this.themeMap = const {},
  });

  /// Clusters [weakTags] using tag co-occurrence from [spotTags].
  ///
  /// [spotTags] maps spot id -> list of tags that appeared in that spot.
  List<SkillTagCluster> clusterWeakTags({
    required List<String> weakTags,
    required Map<String, List<String>> spotTags,
  }) {
    final tagCounts = <String, int>{};
    final pairCounts = <String, Map<String, int>>{};

    for (final tags in spotTags.values) {
      final filtered = tags.where(weakTags.contains).toSet();
      for (final tag in filtered) {
        tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
      }
      for (final a in filtered) {
        for (final b in filtered) {
          if (a == b) continue;
          pairCounts.putIfAbsent(a, () => <String, int>{});
          pairCounts[a]![b] = (pairCounts[a]![b] ?? 0) + 1;
        }
      }
    }

    final uf = _UnionFind();
    for (final tag in weakTags) {
      uf.makeSet(tag);
    }

    for (final a in pairCounts.keys) {
      for (final b in pairCounts[a]!.keys) {
        final co = pairCounts[a]![b]!.toDouble();
        final minCount = min(tagCounts[a] ?? 0, tagCounts[b] ?? 0).toDouble();
        if (minCount == 0) continue;
        final freq = co / minCount;
        if (freq >= linkPercentage) {
          uf.union(a, b);
        }
      }
    }

    final groups = uf.groups();
    final clusters = <SkillTagCluster>[];
    var idx = 0;
    for (final members in groups.values) {
      final sorted = members.toList()
        ..sort((a, b) => (tagCounts[b] ?? 0).compareTo(tagCounts[a] ?? 0));
      final trimmed = sorted.take(maxClusterSize).toList();
      final top = trimmed.first;
      final theme = themeMap[top] ?? top;
      clusters.add(
        SkillTagCluster(
          tags: trimmed,
          clusterId: 'cluster_${idx++}',
          themeName: theme,
        ),
      );
    }
    return clusters;
  }
}

class _UnionFind {
  final Map<String, String> _parent = {};

  void makeSet(String x) => _parent.putIfAbsent(x, () => x);

  String find(String x) {
    final p = _parent[x];
    if (p == null) {
      _parent[x] = x;
      return x;
    }
    if (p != x) {
      _parent[x] = find(p);
    }
    return _parent[x]!;
  }

  void union(String a, String b) {
    final pa = find(a);
    final pb = find(b);
    if (pa != pb) {
      _parent[pa] = pb;
    }
  }

  Map<String, List<String>> groups() {
    final result = <String, List<String>>{};
    for (final k in _parent.keys) {
      final root = find(k);
      result.putIfAbsent(root, () => []).add(k);
    }
    return result;
  }
}
