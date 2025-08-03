import 'package:collection/collection.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import '../models/v2/training_pack_template_v2.dart';
import 'pack_library_loader_service.dart';
import 'pack_unlocking_rules_engine.dart';
import 'tag_mastery_service.dart';
import 'training_progress_service.dart';
import 'training_pack_stats_service.dart';

class SuggestedNextPackEngine {
  final TagMasteryService mastery;
  final List<TrainingPackTemplateV2>? _libraryOverride;

  SuggestedNextPackEngine({required this.mastery, List<TrainingPackTemplateV2>? library})
      : _libraryOverride = library;

  final Map<String, TrainingPackTemplateV2?> _cache = {};
  final Map<String, DateTime> _cacheTime = {};

  Future<TrainingPackTemplateV2?> suggestNextPack({required String currentPackId}) async {
    final cached = _cache[currentPackId];
    final time = _cacheTime[currentPackId];
    if (cached != null &&
        time != null &&
        DateTime.now().difference(time) < const Duration(hours: 6)) {
      return cached;
    }

    await PackLibraryLoaderService.instance.loadLibrary();
    final library = _libraryOverride ?? PackLibraryLoaderService.instance.library;
    final current = library.firstWhereOrNull((p) => p.id == currentPackId);
    if (current == null) return null;

    final focusTags = {
      for (final t in current.tags) t.trim().toLowerCase()
    };
    final weakTags = (await mastery.getWeakTags()).map((e) => e.toLowerCase());
    focusTags.addAll(weakTags);

    final prefs = await PreferencesService.getInstance();
    final scored = <(TrainingPackTemplateV2, double)>[];

    for (final p in library) {
      if (p.id == current.id) continue;
      if (!await PackUnlockingRulesEngine.instance.isUnlocked(p)) continue;
      if (await TrainingPackStatsService.isMastered(p.id)) continue;

      final completed = prefs.getBool('completed_tpl_${p.id}') == true;
      final progress = await TrainingProgressService.instance.getProgress(p.id);

      final tags = {for (final t in p.tags) t.trim().toLowerCase()};
      final overlap = tags.intersection(focusTags).length.toDouble();

      var score = overlap * 2;
      score += completed ? 0 : 1;
      score += (1 - progress);
      if (p.trainingType == current.trainingType) score += 0.5;

      scored.add((p, score));
    }

    scored.sort((a, b) => b.$2.compareTo(a.$2));
    final result = scored.isNotEmpty ? scored.first.$1 : null;
    _cache[currentPackId] = result;
    _cacheTime[currentPackId] = DateTime.now();
    return result;
  }
}
