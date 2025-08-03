
import 'booster_queue_service.dart';
import 'package:poker_analyzer/services/preferences_service.dart';
import 'theory_tag_decay_tracker.dart';
import 'user_action_logger.dart';

/// Checks booster usage and surfaces reminders for decayed skills.
class DecayBoosterReminderEngine {
  final BoosterQueueService queue;
  final TheoryTagDecayTracker decay;
  final UserActionLogger logger;
  final Duration unusedThreshold;
  final double decayThreshold;

  DecayBoosterReminderEngine({
    BoosterQueueService? queue,
    TheoryTagDecayTracker? decay,
    UserActionLogger? logger,
    this.unusedThreshold = const Duration(days: 7),
    this.decayThreshold = 50.0,
  })  : queue = queue ?? BoosterQueueService.instance,
        decay = decay ?? TheoryTagDecayTracker(),
        logger = logger ?? UserActionLogger.instance;

  static const _lastKey = 'decay_booster_reminder_last';

  /// Returns true if the user should be reminded today.
  Future<bool> shouldShowReminder({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final lastUsed = await queue.lastUsed();
    if (lastUsed != null && current.difference(lastUsed) <= unusedThreshold) {
      return false;
    }

    final prefs = await PreferencesService.getInstance();
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    if (last != null && current.difference(last) < const Duration(days: 1)) {
      return false;
    }

    final scores = await decay.computeDecayScores(now: current);
    final needs = scores.values.any((v) => v > decayThreshold);
    if (!needs) return false;

    await prefs.setString(_lastKey, current.toIso8601String());
    await logger.log('decay_reminder_shown');
    return true;
  }

  /// Returns the tag with the highest decay score above [decayThreshold].
  Future<String?> getTopDecayTag({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final scores = await decay.computeDecayScores(now: current);
    final entries = scores.entries
        .where((e) => e.value > decayThreshold)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return null;
    return entries.first.key;
  }
}
