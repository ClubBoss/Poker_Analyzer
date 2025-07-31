import 'package:shared_preferences/shared_preferences.dart';

import '../models/theory_mini_lesson_node.dart';
import 'mini_lesson_library_service.dart';
import 'mini_lesson_progress_tracker.dart';
import 'inbox_booster_service.dart';
import 'theory_tag_decay_tracker.dart';

/// Passively surfaces inbox reminders for decayed theory tags.
class DecayBoosterReminderService {
  final TheoryTagDecayTracker decay;
  final MiniLessonLibraryService library;
  final MiniLessonProgressTracker progress;
  final InboxBoosterService inbox;
  final double threshold;
  final int maxReminders;
  final Duration rotation;

  DecayBoosterReminderService({
    TheoryTagDecayTracker? decay,
    MiniLessonLibraryService? library,
    MiniLessonProgressTracker? progress,
    InboxBoosterService? inbox,
    this.threshold = 45.0,
    this.maxReminders = 3,
    this.rotation = const Duration(days: 7),
  })  : decay = decay ?? TheoryTagDecayTracker(),
        library = library ?? MiniLessonLibraryService.instance,
        progress = progress ?? MiniLessonProgressTracker.instance,
        inbox = inbox ?? InboxBoosterService.instance;

  static final DecayBoosterReminderService instance =
      DecayBoosterReminderService();

  static const String _prefsKey = 'decay_booster_reminder_last';

  /// Computes decayed tags and queues matching boosters.
  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastStr = prefs.getString(_prefsKey);
    final last = lastStr == null ? null : DateTime.tryParse(lastStr);
    if (last != null && now.difference(last) < rotation) return;

    final scores = await decay.computeDecayScores();
    if (scores.isEmpty) return;

    await library.loadAll();
    final decayed = scores.entries
        .where((e) => e.value > threshold)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    var added = 0;
    for (final e in decayed) {
      if (added >= maxReminders) break;
      final lessons = library.findByTags([e.key]);
      if (lessons.isEmpty) continue;
      final TheoryMiniLessonNode lesson = lessons.first;
      final lastViewed = await progress.lastViewed(lesson.id);
      if (lastViewed != null &&
          now.difference(lastViewed) < const Duration(days: 7)) {
        continue;
      }
      await inbox.addReminder(lesson.id);
      added++;
    }

    if (added > 0) {
      await prefs.setString(_prefsKey, now.toIso8601String());
    }
  }
}
