import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a cluster of related weak skill tags.
class SkillGapCluster {
  final String clusterName;
  final List<String> tags;
  final double avgAccuracy;
  final int occurrenceCount;

  const SkillGapCluster({
    required this.clusterName,
    required this.tags,
    required this.avgAccuracy,
    required this.occurrenceCount,
  });

  Map<String, dynamic> toJson() => {
    'clusterName': clusterName,
    'tags': tags,
    'avgAccuracy': avgAccuracy,
    'occurrenceCount': occurrenceCount,
  };

  factory SkillGapCluster.fromJson(Map<String, dynamic> json) =>
      SkillGapCluster(
        clusterName: json['clusterName'] as String? ?? '',
        tags: (json['tags'] as List?)?.cast<String>() ?? const [],
        avgAccuracy: (json['avgAccuracy'] as num?)?.toDouble() ?? 0,
        occurrenceCount: (json['occurrenceCount'] as num?)?.toInt() ?? 0,
      );
}

/// Historical performance data for a user.
class UserSkillHistory {
  final Map<String, double> tagAccuracy; // 0..1
  final Map<String, int> tagOccurrences;
  final Map<String, String> tagCategories;
  final Map<String, double> decayWeights;

  const UserSkillHistory({
    required this.tagAccuracy,
    required this.tagOccurrences,
    required this.tagCategories,
    this.decayWeights = const {},
  });
}

/// Detects clusters of weak skills based on historical accuracy data.
class AutoSkillGapClusterer {
  AutoSkillGapClusterer({
    this.weaknessThreshold = 0.7,
    SharedPreferences? prefs,
    this.storageKey = 'auto_skill_gap_clusters',
  }) : _prefs = prefs,
       clustersNotifier = ValueNotifier<List<SkillGapCluster>>([]);

  final double weaknessThreshold;
  final String storageKey;
  final SharedPreferences? _prefs;

  /// Notifies listeners with the latest detected clusters.
  final ValueNotifier<List<SkillGapCluster>> clustersNotifier;

  Future<List<SkillGapCluster>> detectWeakSkillClusters(
    UserSkillHistory history,
  ) async {
    final data = <String, _ClusterData>{};

    history.tagAccuracy.forEach((tag, acc) {
      if (acc >= weaknessThreshold) return;
      final count = history.tagOccurrences[tag] ?? 0;
      if (count <= 0) return;
      final category = history.tagCategories[tag] ?? 'misc';
      final weight = history.decayWeights[tag] ?? 1.0;
      final c = data.putIfAbsent(category, () => _ClusterData());
      c.tags.add(tag);
      c.totalAccuracy += acc * count;
      c.totalCount += count;
      c.weightedGap += (1 - acc) * count * weight;
    });

    final clusters = <SkillGapCluster>[];
    data.forEach((name, d) {
      if (d.totalCount == 0) return;
      final avg = d.totalAccuracy / d.totalCount;
      clusters.add(
        SkillGapCluster(
          clusterName: name,
          tags: d.tags.toList(),
          avgAccuracy: avg,
          occurrenceCount: d.totalCount,
        ),
      );
    });

    clusters.sort((a, b) {
      final sevA = (1 - a.avgAccuracy) * a.occurrenceCount;
      final sevB = (1 - b.avgAccuracy) * b.occurrenceCount;
      return sevB.compareTo(sevA);
    });

    clustersNotifier.value = clusters;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    await prefs.setString(
      storageKey,
      jsonEncode(clusters.map((c) => c.toJson()).toList()),
    );
    return clusters;
  }
}

class _ClusterData {
  double totalAccuracy = 0;
  int totalCount = 0;
  double weightedGap = 0;
  final Set<String> tags = <String>{};
}
