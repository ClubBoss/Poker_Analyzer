import 'package:flutter/foundation.dart';

import 'pack_library_service.dart';
import 'weekly_planner_booster_engine.dart';

class BoosterSuggestion {
  final String packId;
  final String tag;

  const BoosterSuggestion({required this.packId, required this.tag});
}

class WeeklyPlannerBoosterFeed {
  final WeeklyPlannerBoosterEngine _engine;
  final PackLibraryService _library;

  final ValueNotifier<Map<String, List<BoosterSuggestion>>> boosters =
      ValueNotifier({});

  WeeklyPlannerBoosterFeed({
    WeeklyPlannerBoosterEngine? engine,
    PackLibraryService? library,
  })  : _engine = engine ?? const WeeklyPlannerBoosterEngine(),
        _library = library ?? PackLibraryService.instance;

  Future<void> refresh() async {
    final raw = await _engine.suggestBoostersForPlannedStages();
    if (raw.isEmpty) {
      boosters.value = {};
      return;
    }
    final result = <String, List<BoosterSuggestion>>{};
    for (final entry in raw.entries) {
      final suggestions = <BoosterSuggestion>[];
      for (final id in entry.value) {
        final tpl = await _library.getById(id);
        final tag = tpl?.meta['tag']?.toString() ?? '';
        suggestions.add(BoosterSuggestion(packId: id, tag: tag));
      }
      if (suggestions.isNotEmpty) {
        result[entry.key] = suggestions;
      }
    }
    boosters.value = result;
  }
}
