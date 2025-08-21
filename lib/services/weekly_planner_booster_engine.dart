import 'package:collection/collection.dart';

import '../models/learning_path_template_v2.dart';
import '../services/learning_path_planner_engine.dart';
import '../services/learning_path_orchestrator.dart';
import '../services/theory_pack_library_service.dart';
import '../services/pack_library_service.dart';
import 'theory_pack_auto_tagger.dart';

/// Suggests booster packs for stages returned by [LearningPathPlannerEngine].
class WeeklyPlannerBoosterEngine {
  final PackLibraryService _library;
  final TheoryPackLibraryService _theoryLibrary;
  final Future<List<String>> Function() _getStageIds;
  final Future<LearningPathTemplateV2> Function() _getPath;

  const WeeklyPlannerBoosterEngine({
    PackLibraryService? library,
    TheoryPackLibraryService? theoryLibrary,
    Future<List<String>> Function()? getStageIds,
    Future<LearningPathTemplateV2> Function()? getPath,
  }) : _library = library ?? PackLibraryService.instance,
       _theoryLibrary = theoryLibrary ?? TheoryPackLibraryService.instance,
       _getStageIds =
           getStageIds ?? LearningPathPlannerEngine.instance.getPlannedStageIds,
       _getPath = getPath ?? LearningPathOrchestrator.instance.resolve;

  /// Returns a map from stage id to recommended booster pack ids.
  Future<Map<String, List<String>>> suggestBoostersForPlannedStages() async {
    final ids = await _getStageIds();
    if (ids.isEmpty) return {};
    await _theoryLibrary.loadAll();
    await _library.recommendedStarter();
    final path = await _getPath();
    const tagger = TheoryPackAutoTagger();
    final result = <String, List<String>>{};

    for (final id in ids) {
      final stage = path.stages.firstWhereOrNull((s) => s.id == id);
      if (stage == null) continue;
      final theoryId = stage.theoryPackId;
      if (theoryId == null) continue;
      final pack = _theoryLibrary.getById(theoryId);
      if (pack == null) continue;
      final tags = tagger.autoTag(pack);
      final boosterIds = <String>{};
      for (final t in tags) {
        final cands = await _library.findBoosterCandidates(t);
        boosterIds.addAll(cands);
      }
      if (boosterIds.isNotEmpty) {
        result[id] = boosterIds.toList();
      }
    }
    return result;
  }
}
