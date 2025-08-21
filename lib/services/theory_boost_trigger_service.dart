import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';
import 'recap_completion_tracker.dart';
import 'recap_effectiveness_analyzer.dart';
import 'theory_replay_cooldown_manager.dart';
import 'package:collection/collection.dart';

/// Determines when theory boosters should be shown after recaps.
class TheoryBoostTriggerService {
  final RecapCompletionTracker tracker;
  final RecapEffectivenessAnalyzer analyzer;
  final MiniLessonLibraryService library;
  final Duration cooldown;

  TheoryBoostTriggerService({
    RecapCompletionTracker? tracker,
    RecapEffectivenessAnalyzer? analyzer,
    MiniLessonLibraryService? library,
    this.cooldown = const Duration(hours: 12),
  })  : tracker = tracker ?? RecapCompletionTracker.instance,
        analyzer = analyzer ?? RecapEffectivenessAnalyzer.instance,
        library = library ?? MiniLessonLibraryService.instance;

  static final TheoryBoostTriggerService instance = TheoryBoostTriggerService();

  Future<bool> _underCooldown(String tag) =>
      TheoryReplayCooldownManager.isUnderCooldown(
        'boost:$tag',
        cooldown: cooldown,
      );

  Future<void> _markCooldown(String tag) =>
      TheoryReplayCooldownManager.markSuggested('boost:$tag');

  /// Returns true if [tag] warrants a booster suggestion.
  Future<bool> shouldTriggerBoost(String tag) async {
    final key = tag.trim().toLowerCase();
    if (key.isEmpty) return false;
    if (await _underCooldown(key)) return false;
    await analyzer.refresh();
    if (!analyzer.isUnderperforming(key)) return false;
    final freq = await tracker.tagFrequency();
    if ((freq[key] ?? 0) < 1) return false;
    await _markCooldown(key);
    return true;
  }

  /// Returns a lesson to boost [tag] if conditions are met.
  Future<TheoryMiniLessonNode?> getBoostCandidate(String tag) async {
    if (!await shouldTriggerBoost(tag)) return null;
    await library.loadAll();
    return library.findByTags([tag]).firstOrNull;
  }
}
