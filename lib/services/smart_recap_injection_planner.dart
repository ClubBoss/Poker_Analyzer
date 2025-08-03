import 'dart:convert';
import 'package:poker_analyzer/services/preferences_service.dart';


import 'booster_path_history_service.dart';
import 'recap_effectiveness_analyzer.dart';

/// Planned recap tag injection.
class RecapInjectionPlan {
  final List<String> tagIds;
  final DateTime plannedAt;

  const RecapInjectionPlan({required this.tagIds, required this.plannedAt});

  Map<String, dynamic> toJson() => {
        'tags': tagIds,
        'time': plannedAt.toIso8601String(),
      };

  factory RecapInjectionPlan.fromJson(Map<String, dynamic> json) {
    final tags = <String>[];
    final list = json['tags'];
    if (list is List) {
      for (final t in list) {
        if (t is String) tags.add(t);
      }
    }
    final ts = DateTime.tryParse(json['time']?.toString() ?? '') ?? DateTime.now();
    return RecapInjectionPlan(tagIds: tags, plannedAt: ts);
  }
}

class SmartRecapInjectionPlanner {
  final BoosterPathHistoryService history;
  final RecapEffectivenessAnalyzer analyzer;

  SmartRecapInjectionPlanner({
    BoosterPathHistoryService? history,
    RecapEffectivenessAnalyzer? analyzer,
  })  : history = history ?? BoosterPathHistoryService.instance,
        analyzer = analyzer ?? RecapEffectivenessAnalyzer.instance;

  static final SmartRecapInjectionPlanner instance = SmartRecapInjectionPlanner();

  static const _prefsKey = 'smart_recap_injection_plan';

  Future<RecapInjectionPlan?> _loadLast() async {
    final prefs = await PreferencesService.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return null;
    try {
      final data = jsonDecode(raw);
      if (data is Map) {
        return RecapInjectionPlan.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
    return null;
  }

  Future<void> _save(RecapInjectionPlan plan) async {
    final prefs = await PreferencesService.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(plan.toJson()));
  }

  /// Computes tag ids to inject into the recap banner.
  Future<RecapInjectionPlan?> computePlan({
    int maxTags = 2,
    Duration excludeRecent = const Duration(days: 3),
  }) async {
    if (maxTags <= 0) return null;
    await analyzer.refresh();
    final stats = analyzer.stats;
    if (stats.isEmpty) return null;
    final histMap = await history.getHistory();
    final now = DateTime.now();
    final last = await _loadLast();

    final candidates = <_Candidate>[];
    stats.forEach((tag, eff) {
      final hist = histMap[tag];
      if (hist != null && now.difference(hist.lastInteraction) < excludeRecent) {
        return;
      }
      final urgency =
          (1 - eff.repeatRate) + 1 / (eff.count + 1) + 1 / (eff.averageDuration.inSeconds + 1);
      final recency = hist == null
          ? 1000.0
          : now.difference(hist.lastInteraction).inHours.toDouble();
      final score = urgency * 2 + recency / 24.0;
      candidates.add(_Candidate(tag, score));
    });

    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.score.compareTo(a.score));

    final tags = <String>[];
    for (final c in candidates) {
      if (tags.length >= maxTags) break;
      if (last != null && last.tagIds.contains(c.tag)) continue;
      tags.add(c.tag);
    }

    if (tags.isEmpty) return null;
    final plan = RecapInjectionPlan(tagIds: tags, plannedAt: now);
    await _save(plan);
    return plan;
  }
}

class _Candidate {
  final String tag;
  final double score;
  const _Candidate(this.tag, this.score);
}
