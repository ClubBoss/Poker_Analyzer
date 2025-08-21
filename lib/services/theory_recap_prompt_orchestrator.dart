import 'theory_booster_candidate_picker.dart';
import 'theory_reinforcement_queue_service.dart';
import 'theory_replay_cooldown_manager.dart';
import 'theory_prompt_dismiss_tracker.dart';
import '../models/theory_mini_lesson_node.dart';

/// Decides which theory lesson recap prompt to show based on queues and cooldowns.
class TheoryRecapPromptOrchestrator {
  final TheoryReinforcementQueueService queue;
  final TheoryBoosterCandidatePicker boosterPicker;

  final Set<String> _suggested = <String>{};

  TheoryRecapPromptOrchestrator({
    TheoryReinforcementQueueService? queue,
    TheoryBoosterCandidatePicker? boosterPicker,
  })  : queue = queue ?? TheoryReinforcementQueueService.instance,
        boosterPicker = boosterPicker ?? const TheoryBoosterCandidatePicker();

  /// Picks a lesson for recap if one is due and not under cooldown.
  Future<TheoryMiniLessonNode?> pickRecapCandidate() async {
    final dueLessons = await queue.getDueLessons();
    for (final l in dueLessons) {
      if (_suggested.contains(l.id)) continue;
      if (await TheoryReplayCooldownManager.isUnderCooldown(l.id)) continue;
      if (await TheoryPromptDismissTracker.instance.isRecentlyDismissed(l.id)) {
        continue;
      }
      _suggested.add(l.id);
      return l;
    }

    final boosterLessons = await boosterPicker.getTopBoosterCandidates();
    for (final l in boosterLessons) {
      if (_suggested.contains(l.id)) continue;
      if (await TheoryReplayCooldownManager.isUnderCooldown(l.id)) continue;
      if (await TheoryPromptDismissTracker.instance.isRecentlyDismissed(l.id)) {
        continue;
      }
      _suggested.add(l.id);
      return l;
    }
    return null;
  }
}
