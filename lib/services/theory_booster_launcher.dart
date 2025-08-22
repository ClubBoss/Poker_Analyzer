import '../models/theory_mini_lesson_node.dart';
import '../models/player_profile.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../core/training/library/training_pack_library_v2.dart';
import '../core/training/engine/training_type_engine.dart';
import 'tag_mastery_service.dart';
import 'training_session_launcher.dart';

/// Launches a booster pack relevant to a theory mini lesson.
class TheoryBoosterLauncher {
  final TagMasteryService mastery;
  final TrainingPackLibraryV2 library;
  final TrainingSessionLauncher launcher;
  final PlayerProfile? profile;

  TheoryBoosterLauncher({
    required this.mastery,
    this.profile,
    TrainingPackLibraryV2? library,
    this.launcher = const TrainingSessionLauncher(),
  }) : library = library ?? TrainingPackLibraryV2.instance;

  /// Selects and launches the best booster for [lesson].
  /// Returns the chosen template or `null` if none found.
  Future<TrainingPackTemplateV2?> launchBoosterFor(
    TheoryMiniLessonNode lesson,
  ) async {
    final tagSet = <String>{
      for (final t in lesson.tags) t.toLowerCase(),
      if (profile != null)
        for (final t in profile!.tags) t.toLowerCase(),
    };
    if (tagSet.isEmpty) return null;

    await library.loadFromFolder();
    final all = library.filterBy(type: TrainingType.pushFold);
    final candidates = <TrainingPackTemplateV2>[];
    for (final p in all) {
      final packTags = p.tags.map((e) => e.toLowerCase()).toSet();
      if (packTags.intersection(tagSet).isNotEmpty) {
        candidates.add(p);
      }
    }
    if (candidates.isEmpty) return null;

    final moderate = [
      for (final p in candidates)
        if (p.spotCount >= 5 && p.spotCount <= 10) p,
    ];
    final pool = moderate.isNotEmpty ? moderate : candidates;

    final masteryMap = await mastery.computeMastery();
    pool.sort((a, b) {
      final aScore = _scorePack(a, masteryMap, tagSet);
      final bScore = _scorePack(b, masteryMap, tagSet);
      return aScore.compareTo(bScore);
    });

    final chosen = pool.first;
    await launcher.launch(chosen);
    return chosen;
  }

  double _scorePack(
    TrainingPackTemplateV2 p,
    Map<String, double> masteryMap,
    Set<String> relevant,
  ) {
    var sum = 0.0;
    var count = 0;
    for (final t in p.tags) {
      final lc = t.toLowerCase();
      if (relevant.contains(lc)) {
        sum += masteryMap[lc] ?? 1.0;
        count++;
      }
    }
    return count == 0 ? 1.0 : sum / count;
  }
}
