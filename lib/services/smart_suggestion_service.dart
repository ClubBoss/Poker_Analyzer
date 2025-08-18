import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/training/generation/yaml_reader.dart';
import '../models/training_pack.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'pack_tag_index_service.dart';
import 'training_pack_storage_service.dart';
import 'template_storage_service.dart';
import 'goals_service.dart';
import 'mistake_review_pack_service.dart';

class SmartSuggestionService {
  final TrainingPackStorageService storage;
  final TemplateStorageService templates;
  SmartSuggestionService({required this.storage, required this.templates});

  List<TrainingPack> getSuggestions() {
    final now = DateTime.now();
    final list = storage.packs.toList();
    if (list.isEmpty) {
      final tpls = templates.templates.where((t) => t.trending).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return [
        for (final t in tpls.take(3))
          TrainingPack(
            name: t.name,
            description: t.description,
            gameType: t.gameType,
            tags: t.tags,
            hands: const [],
            spots: const [],
            difficulty: t.difficultyLevel,
            isBuiltIn: t.isBuiltIn,
          ),
      ];
    }
    list.sort((a, b) {
      final ascore =
          (1 - a.pctComplete) * 100 + now.difference(a.lastAttemptDate).inDays;
      final bscore =
          (1 - b.pctComplete) * 100 + now.difference(b.lastAttemptDate).inDays;
      return bscore.compareTo(ascore);
    });
    return list.take(3).toList();
  }

  Map<String, List<TrainingPack>> getExtendedSuggestions(
    GoalsService goals,
    MistakeReviewPackService mistakes, {
    int limit = 20,
  }) {
    final now = DateTime.now();
    final packs = storage.packs.toList();

    List<TrainingPack> almost = [
      for (final p in packs)
        if (p.pctComplete >= 0.6 && p.pctComplete < 1) p,
    ]..sort((a, b) => b.pctComplete.compareTo(a.pctComplete));

    List<TrainingPack> stale = [
      for (final p in packs)
        if (now.difference(p.lastAttemptDate).inDays > 7) p,
    ]..sort((a, b) => a.lastAttemptDate.compareTo(b.lastAttemptDate));

    final goal = goals.currentGoal;
    List<TrainingPack> goalPacks = [];
    if (goal != null) {
      for (final p in packs) {
        if (p.hands.any(goal.isViolatedBy)) {
          goalPacks.add(p);
        }
      }
    }

    final mistakesPack = mistakes.pack;
    List<TrainingPack> mistakeList = mistakesPack == null ? [] : [mistakesPack];

    almost = almost.take(limit).toList();
    stale = stale.take(limit).toList();
    goalPacks = goalPacks.take(limit).toList();
    mistakeList = mistakeList.take(limit).toList();

    return {
      'almost': almost,
      'stale': stale,
      'goal': goalPacks,
      'mistakes': mistakeList,
    };
  }

  Future<List<String>> suggestRelated(List<String> tags) async {
    const index = PackTagIndexService();
    final paths = await index.search(tags, mode: TagFilterMode.and);
    if (paths.isEmpty) return [];
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs
        .getKeys()
        .where(
          (k) => k.startsWith('completed_tpl_') && prefs.getBool(k) == true,
        )
        .map((k) => k.substring('completed_tpl_'.length))
        .toSet();
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'training_packs', 'library'));
    const reader = YamlReader();
    final query = [for (final t in tags) t.trim().toLowerCase()];
    final entries = <MapEntry<String, double>>[];
    for (final rel in paths) {
      final file = File(p.join(dir.path, rel));
      if (!file.existsSync()) continue;
      try {
        final map = reader.read(await file.readAsString());
        final tpl = TrainingPackTemplateV2.fromJson(map);
        if (completed.contains(tpl.id)) continue;
        final tplTags = [for (final t in tpl.tags) t.trim().toLowerCase()];
        final matches = query.where(tplTags.contains).length.toDouble();
        final rank = (tpl.meta['rankScore'] as num?)?.toDouble() ?? 0;
        entries.add(MapEntry(rel, matches + rank));
      } catch (_) {}
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    return [for (final e in entries.take(5)) e.key];
  }
}
