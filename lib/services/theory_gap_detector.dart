import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/theory_gap.dart';
import 'skill_tag_coverage_tracker.dart';
import 'preferences_service.dart';

/// Detects missing or under-covered theory topics across the library.
class TheoryGapDetector {
  final Map<String, List<String>> clusters;
  final SkillTagCoverageTracker coverageTracker;
  final Map<String, List<String>> theoryIndex;
  final Map<String, bool> linkStatus;
  final Map<String, DateTime> topicUpdated;
  final int targetCoveragePerTopic;
  final int minTheoryLinksPerPack;
  final int freshnessWindowDays;

  final ValueNotifier<List<TheoryGap>> gapsNotifier =
      ValueNotifier<List<TheoryGap>>(<TheoryGap>[]);

  TheoryGapDetector({
    Map<String, List<String>>? clusters,
    SkillTagCoverageTracker? coverageTracker,
    Map<String, List<String>>? theoryIndex,
    Map<String, bool>? linkStatus,
    Map<String, DateTime>? topicUpdated,
    this.targetCoveragePerTopic = 5,
    this.minTheoryLinksPerPack = 1,
    this.freshnessWindowDays = 30,
  }) : clusters = clusters ?? const <String, List<String>>{},
       coverageTracker = coverageTracker ?? SkillTagCoverageTracker(),
       theoryIndex = theoryIndex ?? const <String, List<String>>{},
       linkStatus = linkStatus ?? const <String, bool>{},
       topicUpdated = topicUpdated ?? const <String, DateTime>{};

  /// Scans all topics and updates [gapsNotifier] with detected gaps.
  Future<List<TheoryGap>> detectGaps() async {
    final topics = <String>{}
      ..addAll(clusters.keys)
      ..addAll(theoryIndex.keys)
      ..addAll(coverageTracker.skillTagCounts.keys);
    final now = DateTime.now();
    final gaps = <TheoryGap>[];
    for (final topic in topics) {
      final coverage = coverageTracker.skillTagCounts[topic] ?? 0;
      final candidates = <String>[
        for (final p in clusters[topic] ?? const <String>[])
          if (!(linkStatus[p] ?? false)) p,
      ];
      final target = targetCoveragePerTopic;
      final severity = (target - coverage).clamp(0, target);
      final hasTheory = (theoryIndex[topic] ?? const []).isNotEmpty;
      final needsGap =
          severity > 0 ||
          !hasTheory ||
          candidates.length < minTheoryLinksPerPack;
      if (!needsGap) continue;
      final updated = topicUpdated[topic];
      var freshnessBoost = 1.0;
      if (updated != null) {
        final age = now.difference(updated).inDays;
        if (age > freshnessWindowDays) freshnessBoost = 1.5;
      }
      final base = severity > 0
          ? severity.toDouble()
          : candidates.length.toDouble();
      final priority = base * freshnessBoost;
      gaps.add(
        TheoryGap(
          topic: topic,
          coverageCount: coverage,
          targetCoverage: target,
          candidatePacks: candidates,
          priorityScore: priority,
        ),
      );
    }
    gaps.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    gapsNotifier.value = gaps;
    await _saveToPrefs(gaps);
    return gaps;
  }

  Future<void> _saveToPrefs(List<TheoryGap> gaps) async {
    final prefs = await PreferencesService.getInstance();
    final data = jsonEncode(gaps.map((g) => g.toJson()).toList());
    await prefs.setString(SharedPrefsKeys.theoryGapReport, data);
  }

  /// Loads previously detected gaps from [SharedPreferences].
  Future<List<TheoryGap>> loadFromPrefs() async {
    final prefs = await PreferencesService.getInstance();
    final data = prefs.getString(SharedPrefsKeys.theoryGapReport);
    if (data == null) return <TheoryGap>[];
    final list = (jsonDecode(data) as List)
        .map((e) => TheoryGap.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    return list;
  }

  /// Exports a remediation plan for automatic theory link injection.
  Map<String, List<String>> exportRemediationPlan() {
    final plan = <String, List<String>>{};
    for (final g in gapsNotifier.value) {
      if (g.candidatePacks.isNotEmpty) {
        plan[g.topic] = List<String>.from(g.candidatePacks);
      }
    }
    return plan;
  }
}
