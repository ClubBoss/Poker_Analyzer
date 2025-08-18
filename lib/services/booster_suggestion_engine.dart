import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../models/mistake_insight.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/training_history_entry_v2.dart';
import '../models/mistake_tag_history_entry.dart';
import '../core/training/library/training_pack_library_v2.dart';
import 'mistake_tag_insights_service.dart';
import 'mistake_tag_cluster_service.dart';
import 'training_pack_stats_service_v2.dart';
import 'training_history_service_v2.dart';
import 'theory_pack_generator_service.dart';
import 'theory_yaml_importer.dart';
import 'mini_lesson_library_service.dart';
import 'recap_effectiveness_analyzer.dart';
import 'theory_replay_cooldown_manager.dart';
import '../models/theory_mini_lesson_node.dart';

class BoosterSuggestionEngine {
  const BoosterSuggestionEngine();

  /// Returns the id of the best booster pack to recommend.
  ///
  /// [library] and other optional parameters are mainly for testing.
  Future<String?> suggestBooster({
    List<TrainingPackTemplateV2>? library,
    Map<String, double>? improvement,
    List<MistakeInsight>? insights,
    List<TrainingHistoryEntryV2>? history,
    DateTime? now,
  }) async {
    final current = now ?? DateTime.now();
    final improvementMap =
        improvement ?? await TrainingPackStatsServiceV2.improvementByTag();
    insights ??= await const MistakeTagInsightsService().buildInsights(
      sortByEvLoss: true,
    );
    history ??= await TrainingHistoryServiceV2.getHistory(limit: 50);

    await TrainingPackLibraryV2.instance.loadFromFolder();
    final packs = library ?? TrainingPackLibraryV2.instance.packs;

    final recentCutoff = current.subtract(const Duration(days: 3));
    final recentPackIds = <String>{
      for (final h in history)
        if (h.timestamp.isAfter(recentCutoff)) h.packId,
    };

    final boosterMap = <String, TrainingPackTemplateV2>{};
    for (final p in packs) {
      if (p.meta['type'] == 'booster') {
        final tag = p.meta['tag']?.toString().toLowerCase();
        if (tag != null && tag.isNotEmpty) {
          boosterMap[tag] = p;
        }
      }
    }
    if (boosterMap.isEmpty || insights.isEmpty) return null;

    const threshold = 0.05;
    const clusterService = MistakeTagClusterService();

    String? bestId;
    for (final i in insights) {
      final cluster = clusterService.getClusterForTag(i.tag);
      final key = cluster.label.toLowerCase();
      final imp = improvementMap[key] ?? 1.0;
      if (imp <= threshold) {
        final pack = boosterMap[key];
        if (pack != null && !recentPackIds.contains(pack.id)) {
          bestId = pack.id;
          break;
        }
      }
    }

    if (bestId != null) return bestId;

    for (final i in insights) {
      final cluster = clusterService.getClusterForTag(i.tag);
      final key = cluster.label.toLowerCase();
      final pack = boosterMap[key];
      if (pack != null && !recentPackIds.contains(pack.id)) {
        return pack.id;
      }
    }

    return null;
  }

  /// Returns mini lessons worth replaying based on recap history.
  Future<List<TheoryMiniLessonNode>> getRecommendedBoosters({
    int maxCount = 3,
  }) async {
    if (maxCount <= 0) return [];
    await RecapEffectivenessAnalyzer.instance.refresh();
    await MiniLessonLibraryService.instance.loadAll();

    final tags = RecapEffectivenessAnalyzer.instance.suppressedTags();
    if (tags.isEmpty) return [];

    final lessons = <TheoryMiniLessonNode>[];
    for (final tag in tags) {
      if (lessons.length >= maxCount) break;
      final key = tag.trim().toLowerCase();
      if (key.isEmpty) continue;
      if (await TheoryReplayCooldownManager.isUnderCooldown('boost:$key')) {
        continue;
      }
      final nodes = MiniLessonLibraryService.instance.findByTags([key]);
      if (nodes.isEmpty) continue;
      lessons.add(nodes.first);
    }
    return lessons;
  }

  /// Generates a simple YAML booster for the first tag in [mistake] if no
  /// existing booster pack matches the tag and `meta.generatedBy`.
  Future<void> generateIfMissing(
    MistakeTagHistoryEntry mistake, {
    String dir = 'yaml_out/boosters',
  }) async {
    final importer = const TheoryYamlImporter();
    final packs = await importer.importFromDirectory(dir);

    final existing = <String>{};
    for (final p in packs) {
      final meta = p.meta;
      if (meta['generatedBy'] != 'BoosterPackLibraryBuilder v1') continue;
      final tag = meta['tag']?.toString().toLowerCase();
      if (tag != null && tag.isNotEmpty) existing.add(tag);
    }

    if (mistake.tags.isEmpty) return;
    final tag = mistake.tags.first.label.toLowerCase();
    if (existing.contains(tag)) return;

    const generator = TheoryPackGeneratorService();
    final tpl = generator.generateForTag(tag);
    final map = tpl.toJson();
    map['id'] = const Uuid().v4();
    final meta = Map<String, dynamic>.from(map['meta'] ?? {});
    meta['type'] = 'booster';
    meta['tag'] = tag;
    meta['generatedBy'] = 'BoosterSuggestionEngine v1';
    map['meta'] = meta;
    final booster = TrainingPackTemplateV2.fromJson(
      Map<String, dynamic>.from(map),
    );

    final outDir = Directory(dir);
    await outDir.create(recursive: true);
    final file = File(p.join(outDir.path, '${booster.id}.yaml'));
    await file.writeAsString(booster.toYamlString());
    debugPrint('booster auto-generated for $tag');
  }
}
