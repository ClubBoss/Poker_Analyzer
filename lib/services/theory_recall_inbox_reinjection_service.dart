import 'package:shared_preferences/shared_preferences.dart';

import '../models/theory_mini_lesson_node.dart';
import 'theory_booster_recall_engine.dart';
import 'inbox_booster_service.dart';

/// Periodically requeues dismissed recall boosters into the inbox.
class TheoryRecallInboxReinjectionService {
  final TheoryBoosterRecallEngine recall;
  final InboxBoosterService inbox;
  final Duration cooldown;

  TheoryRecallInboxReinjectionService({
    TheoryBoosterRecallEngine? recall,
    InboxBoosterService? inbox,
    this.cooldown = const Duration(days: 3),
  }) : recall = recall ?? TheoryBoosterRecallEngine.instance,
       inbox = inbox ?? InboxBoosterService.instance;

  static const String _prefsKey = 'theory_recall_inbox_reinjection_last';

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Executes reinjection once per day if suitable candidates exist.
  Future<void> start() async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastStr = prefs.getString(_prefsKey);
    final last = lastStr == null ? null : DateTime.tryParse(lastStr);
    if (last != null && _sameDay(last, now)) return;
    await prefs.setString(_prefsKey, now.toIso8601String());

    final lessons = await recall.recallDismissedUnlaunched(since: cooldown);
    if (lessons.isEmpty) return;
    lessons.sort((a, b) => a.id.compareTo(b.id));
    final TheoryMiniLessonNode lesson = lessons.first;
    await inbox.inject(lesson);
    await recall.recordSuggestion(lesson.id);
  }
}
