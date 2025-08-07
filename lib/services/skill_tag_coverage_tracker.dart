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
  final Map<String, int> _aggregateCounts = <String, int>{};
  int _aggregateTotalTags = 0;

  SkillTagCoverageTracker({
    this.allTags = const <String>[],
    this.overloadThreshold = 50,
  });

  /// Analyzes [pack] and updates global coverage counts.
  SkillTagStats analyzePack(TrainingPackModel pack) => analyze(pack.spots);

  /// Computes tag coverage statistics for [spots].
  SkillTagStats analyze(List<TrainingPackSpot> spots) {
    final counts = <String, int>{};
    final perSpot = <String, List<String>>{};
    var total = 0;
    for (final spot in spots) {
      final tags = List<String>.from(spot.tags);
      perSpot[spot.id] = tags;
      total += tags.length;
      for (final tag in tags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
        _aggregateCounts[tag] = (_aggregateCounts[tag] ?? 0) + 1;
      }
    }
    _aggregateTotalTags += total;
    final unused = allTags.where((t) => (counts[t] ?? 0) == 0).toList();
    final overloaded = counts.entries
        .where((e) => e.value > overloadThreshold)
        .map((e) => e.key)
        .toList();
    return SkillTagStats(
      tagCounts: Map<String, int>.from(counts),
      totalTags: total,
      unusedTags: unused,
      overloadedTags: overloaded,
      spotTags: perSpot,
    );
  }

  /// Returns the aggregated coverage across all analyzed packs.
  SkillTagStats get aggregateReport {
    final unused = allTags
        .where((t) => (_aggregateCounts[t] ?? 0) == 0)
        .toList();
    final overloaded = _aggregateCounts.entries
        .where((e) => e.value > overloadThreshold)
        .map((e) => e.key)
        .toList();
    return SkillTagStats(
      tagCounts: Map<String, int>.from(_aggregateCounts),
      totalTags: _aggregateTotalTags,
      unusedTags: unused,
      overloadedTags: overloaded,
    );
  }

  /// Logs the aggregate coverage summary to [sink] or a default file.
  Future<void> logSummary([IOSink? sink]) async {
    final report = aggregateReport;
    final out =
        sink ?? File('skill_tag_coverage.log').openWrite(mode: FileMode.append);
    out.writeln('Total tags: ${report.totalTags}');
    for (final entry in report.tagCounts.entries) {
      out.writeln('${entry.key}: ${entry.value}');
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
        final norm = tag.trim().toLowerCase();
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
    final normalizedAll = allTags.map((e) => e.trim().toLowerCase()).toSet();
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
    final data = jsonEncode({
      'tagCounts': tagCounts,
      'unusedTags': unusedTags,
    });
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
}
