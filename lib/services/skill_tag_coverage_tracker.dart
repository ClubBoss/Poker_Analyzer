import 'dart:convert';
import 'dart:io';

import '../models/training_pack_model.dart';
import '../models/v2/training_pack_spot.dart';
import '../models/skill_tag_stats.dart';
import '../core/training/generation/yaml_writer.dart';
import '../utils/app_logger.dart';
import 'preferences_service.dart';

/// Tracks tag frequency and coverage across generated spots.
class SkillTagCoverageTracker {
  final List<String> allTags;
  final int overloadThreshold;
  final Map<String, int> skillTagCounts = <String, int>{};
  final Map<String, String> tagCategoryMap;
  final Map<String, int> categoryCounts = <String, int>{};
  final Map<String, Set<String>> _seenTagsByCategory = <String, Set<String>>{};
  final Map<String, Set<String>> _allTagsByCategory = <String, Set<String>>{};
  final Map<String, Set<String>> _tagPacks = <String, Set<String>>{};
  final Map<String, DateTime> _tagLastUpdated = <String, DateTime>{};
  int _totalTags = 0;

  SkillTagCoverageTracker({
    this.allTags = const <String>[],
    this.overloadThreshold = 50,
    Map<String, String>? tagCategoryMap,
    String categoryFile = 'assets/skill_tag_categories.json',
  }) : tagCategoryMap = tagCategoryMap ?? _loadCategoryMap(categoryFile) {
    _initCategories();
  }

  static Map<String, String> _loadCategoryMap(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) return {};
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      return data.map(
        (key, value) =>
            MapEntry(key.toString().toLowerCase(), value.toString()),
      );
    } catch (_) {
      return {};
    }
  }

  void _initCategories() {
    _allTagsByCategory.clear();
    for (final tag in allTags) {
      final norm = _normalize(tag);
      final cat = tagCategoryMap[norm] ?? 'uncategorized';
      (_allTagsByCategory[cat] ??= <String>{}).add(norm);
    }
  }

  /// Analyzes [pack] and updates global coverage counts.
  SkillTagStats analyzePack(TrainingPackModel pack) =>
      analyze(pack.spots, packId: pack.id);

  /// Computes tag coverage statistics for [spots].
  SkillTagStats analyze(List<TrainingPackSpot> spots, {String? packId}) {
    final counts = <String, int>{};
    final perSpot = <String, List<String>>{};
    final localCategoryCounts = <String, int>{};
    final localSeenByCategory = <String, Set<String>>{};
    var total = 0;
    for (final spot in spots) {
      final tags = spot.tags.map(_normalize).toList()..sort();
      perSpot[spot.id] = tags;
      total += tags.length;
      for (final tag in tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
        skillTagCounts[tag] = (skillTagCounts[tag] ?? 0) + 1;
        final cat = tagCategoryMap[tag] ?? 'uncategorized';
        categoryCounts[cat] = (categoryCounts[cat] ?? 0) + 1;
        localCategoryCounts[cat] = (localCategoryCounts[cat] ?? 0) + 1;
        (_seenTagsByCategory[cat] ??= <String>{}).add(tag);
        (localSeenByCategory[cat] ??= <String>{}).add(tag);
        if (packId != null) {
          (_tagPacks[tag] ??= <String>{}).add(packId);
        }
        _tagLastUpdated[tag] = DateTime.now();
      }
    }
    _totalTags += total;
    final unused =
        allTags.where((t) => (counts[_normalize(t)] ?? 0) == 0).toList();
    final overloaded = counts.entries
        .where((e) => e.value > overloadThreshold)
        .map((e) => e.key)
        .toList();
    final localCoverage = <String, double>{};
    localSeenByCategory.forEach((cat, set) {
      final totalKnown = _allTagsByCategory[cat]?.length ?? 0;
      localCoverage[cat] =
          totalKnown == 0 ? 1.0 : set.length / totalKnown.toDouble();
    });
    return SkillTagStats(
      tagCounts: Map<String, int>.from(counts),
      totalTags: total,
      unusedTags: unused,
      overloadedTags: overloaded,
      spotTags: perSpot,
      categoryCounts: localCategoryCounts,
      categoryCoverage: localCoverage,
    );
  }

  /// Returns tag coverage counts for [spots]. Tags are normalized to lowercase
  /// and can be filtered by [minCount].
  Map<String, int> getSkillTagCoverage(
    List<TrainingPackSpot> spots, {
    int minCount = 0,
  }) {
    final counts = analyze(spots).tagCounts;
    if (minCount > 0) {
      counts.removeWhere((_, value) => value < minCount);
    }
    return counts;
  }

  /// Groups coverage counts by pack identifier.
  Map<String, Map<String, int>> getCoverageByPack(
    Map<String, List<TrainingPackSpot>> packs, {
    int minCount = 0,
  }) {
    final result = <String, Map<String, int>>{};
    for (final entry in packs.entries) {
      result[entry.key] = getSkillTagCoverage(entry.value, minCount: minCount);
    }
    return result;
  }

  /// Returns the aggregated coverage across all analyzed packs.
  SkillTagStats get aggregateReport {
    final unused = allTags
        .where((t) => (skillTagCounts[_normalize(t)] ?? 0) == 0)
        .toList();
    final overloaded = skillTagCounts.entries
        .where((e) => e.value > overloadThreshold)
        .map((e) => e.key)
        .toList();
    final coverage = <String, double>{};
    _allTagsByCategory.forEach((cat, tags) {
      final seen = _seenTagsByCategory[cat]?.length ?? 0;
      coverage[cat] = tags.isEmpty ? 0 : seen / tags.length.toDouble();
    });
    return SkillTagStats(
      tagCounts: Map<String, int>.from(skillTagCounts),
      totalTags: _totalTags,
      unusedTags: unused,
      overloadedTags: overloaded,
      categoryCounts: Map<String, int>.from(categoryCounts),
      categoryCoverage: coverage,
      packsPerTag: _tagPacks.map((k, v) => MapEntry(k, v.length)),
      tagLastUpdated: Map<String, DateTime>.from(_tagLastUpdated),
    );
  }

  /// Logs the aggregate coverage summary to [sink] or a default file.
  Future<void> logSummary([IOSink? sink]) async {
    final report = aggregateReport;
    final out =
        sink ?? File('skill_tag_coverage.log').openWrite(mode: FileMode.append);
    out.writeln('Skill Coverage Summary:');
    final entries = report.tagCounts.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in entries) {
      out.writeln('- ${entry.key}: ${entry.value}');
    }
    if (report.unusedTags.isNotEmpty) {
      out.writeln('Unused tags: ${report.unusedTags.join(', ')}');
    }
    if (report.overloadedTags.isNotEmpty) {
      out.writeln('Overloaded tags: ${report.overloadedTags.join(', ')}');
    }
    await out.flush();
    if (sink == null) {
      await out.close();
    }
  }

  /// Computes tag usage counts across [packs]. Tags are normalized to lowercase.
  Map<String, int> computeTagCounts(List<TrainingPackModel> packs) {
    final counts = <String, int>{};
    for (final pack in packs) {
      for (final tag in pack.tags) {
        final norm = _normalize(tag);
        if (norm.isEmpty) continue;
        counts[norm] = (counts[norm] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Returns tags from [allTags] that do not appear in [packs]. A warning is
  /// logged listing any uncovered tags.
  List<String> findUnusedTags(
    List<TrainingPackModel> packs,
    Set<String> allTags,
  ) {
    final counts = computeTagCounts(packs);
    final normalizedAll = allTags.map(_normalize).toSet();
    final unused = <String>[
      for (final tag in normalizedAll)
        if (!counts.containsKey(tag)) tag,
    ]..sort();
    if (unused.isNotEmpty) {
      AppLogger.warn('Unused tags: ${unused.join(', ')}');
    }
    return unused;
  }

  /// Persists the coverage report to [SharedPreferences].
  Future<void> saveReportToPrefs({
    required Map<String, int> tagCounts,
    required List<String> unusedTags,
  }) async {
    final prefs = await PreferencesService.getInstance();
    final data = jsonEncode({'tagCounts': tagCounts, 'unusedTags': unusedTags});
    await prefs.setString(SharedPrefsKeys.skillTagCoverageReport, data);
  }

  /// Exports the coverage report as a YAML file at [path].
  Future<void> exportReportAsYaml({
    required Map<String, int> tagCounts,
    required List<String> unusedTags,
    required String path,
  }) async {
    const writer = YamlWriter();
    await writer.write({
      'tagCounts': tagCounts,
      'unusedTags': unusedTags,
    }, path);
  }

  /// Clears all accumulated tag statistics.
  void reset() {
    skillTagCounts.clear();
    categoryCounts.clear();
    _seenTagsByCategory.clear();
    _tagPacks.clear();
    _tagLastUpdated.clear();
    _totalTags = 0;
  }

  String _normalize(String tag) => tag.trim().toLowerCase();

  List<String> underrepresentedCategories({double threshold = 0.6}) {
    final coverage = aggregateReport.categoryCoverage;
    final result = <String>[
      for (final entry in coverage.entries)
        if (entry.value < threshold) entry.key,
    ]..sort((a, b) => coverage[a]!.compareTo(coverage[b]!));
    return result;
  }
}
