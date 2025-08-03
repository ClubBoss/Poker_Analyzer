import 'package:collection/collection.dart';
import 'package:poker_analyzer/services/preferences_service.dart';

import '../models/v2/training_pack_template_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import 'pack_unlocking_rules_engine.dart';
import 'template_storage_service.dart';
import 'tag_mastery_service.dart';
import 'training_path_progress_service.dart';

class SuggestedNextStepEngine {
  final TrainingPathProgressService path;
  final TagMasteryService mastery;
  final TemplateStorageService storage;

  SuggestedNextStepEngine({
    required this.path,
    required this.mastery,
    required this.storage,
  });

  Map<String, List<String>>? _stageCache;
  Map<String, Set<String>>? _completedCache;
  DateTime _cacheTime = DateTime.fromMillisecondsSinceEpoch(0);

  Future<void> _loadCache() async {
    if (_stageCache != null &&
        DateTime.now().difference(_cacheTime) < const Duration(minutes: 10)) {
      return;
    }
    _stageCache = await path.getStages();
    final prefs = await PreferencesService.getInstance();
    _completedCache = {};
    for (final entry in _stageCache!.entries) {
      final done = <String>{};
      for (final id in entry.value) {
        if (prefs.getBool('training_path_completed_$id') ?? false) {
          done.add(id);
        }
      }
      _completedCache![entry.key] = done;
    }
    _cacheTime = DateTime.now();
  }

  bool _stageDone(List<String> ids, Set<String> completed) {
    for (final id in ids) {
      if (!completed.contains(id)) return false;
    }
    return true;
  }

  double _packScore(
    TrainingPackTemplateV2 pack,
    Map<String, double> masteryMap,
  ) {
    var score = 1.0;
    for (final t in pack.tags) {
      final m = masteryMap[t.toLowerCase()];
      if (m != null && m < score) score = m;
    }
    return score;
  }

  Future<TrainingPackTemplateV2?> suggestNext() async {
    await _loadCache();
    final stages = _stageCache ?? {};
    if (stages.isEmpty) return null;

    final masteryMap = await mastery.computeMastery();

    bool previousCompleted = true;
    for (final entry in stages.entries) {
      final packs = entry.value;
      final completed = _completedCache?[entry.key] ?? {};
      if (!previousCompleted) break;

      final incomplete = [for (final id in packs) if (!completed.contains(id)) id];
      if (incomplete.isEmpty) {
        previousCompleted = true;
        continue;
      }

      final candidates = <(TrainingPackTemplateV2, double)>[];
      for (final id in incomplete) {
        final tpl = storage.templates
            .firstWhereOrNull((t) => t.id == id);
        if (tpl == null) continue;
        final tplV2 = TrainingPackTemplateV2.fromTemplate(
          tpl,
          type: TrainingType.pushFold,
        );
        tplV2.trainingType = const TrainingTypeEngine().detectTrainingType(tplV2);
        if (!await PackUnlockingRulesEngine.instance.isUnlocked(tplV2)) {
          continue;
        }
        final score = _packScore(tplV2, masteryMap);
        candidates.add((tplV2, score));
      }

      if (candidates.isNotEmpty) {
        candidates.sort((a, b) => a.$2.compareTo(b.$2));
        return candidates.first.$1;
      }

      previousCompleted = _stageDone(packs, completed);
    }

    return null;
  }
}
