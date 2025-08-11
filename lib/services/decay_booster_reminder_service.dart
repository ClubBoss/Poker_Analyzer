import 'package:shared_preferences/shared_preferences.dart';

import 'inbox_booster_service.dart';
import 'mini_lesson_library_service.dart';
import 'mini_lesson_progress_tracker.dart';
import 'theory_tag_decay_tracker.dart';

/// Surfaces inbox reminders for highly decayed theory tags.
class DecayBoosterReminderService {
  final TheoryTagDecayTracker decay;
  final MiniLessonLibraryService lessons;
  final MiniLessonProgressTracker progress;
  final InboxBoosterService inbox;
  final double threshold;
  final Duration recency;
  final Duration rotation;

  DecayBoosterReminderService({
    TheoryTagDecayTracker? decay,
    MiniLessonLibraryService? lessons,
    MiniLessonProgressTracker? progress,
    InboxBoosterService? inbox,
    this.threshold = 45,
    this.recency = const Duration(days: 7),
    this.rotation = const Duration(days: 7),
  })  : decay = decay ?? TheoryTagDecayTracker(),
        lessons = lessons ?? MiniLessonLibraryService.instance,
        progress = progress ?? MiniLessonProgressTracker.instance,
        inbox = inbox ?? InboxBoosterService.instance;

  static const String _lastKey = 'decay_booster_reminder_last';

  /// Checks decayed tags and queues inbox reminders when needed.
  Future<void> run() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    if (last != null && now.difference(last) < rotation) return;

    final scores = await decay.computeDecayScores(now: now);
    final entries = scores.entries
        .where((e) => e.value > threshold)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int added = 0;
    for (final entry in entries) {
      final tag = entry.key;
      final lessonList = lessons.findByTags([tag]);
      for (final lesson in lessonList) {
        final ts = await progress.lastViewed(lesson.id);
        if (ts != null && now.difference(ts) < recency) continue;
        await inbox.addReminder(lesson.id);
        added++;
        break;
      }
      if (added >= 3) break;
    }

    if (added > 0) {
      await prefs.setString(_lastKey, now.toIso8601String());
    }
  }
}
