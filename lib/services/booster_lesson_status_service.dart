import '../models/theory_mini_lesson_node.dart';
import '../models/booster_lesson_status.dart';
import 'inbox_booster_tracker_service.dart';
import 'booster_path_history_service.dart';
import '../models/booster_path_log_entry.dart';

/// Resolves [BoosterLessonStatus] for theory mini lessons.
class BoosterLessonStatusService {
  final InboxBoosterTrackerService tracker;
  final BoosterPathHistoryService history;

  BoosterLessonStatusService({
    InboxBoosterTrackerService? tracker,
    BoosterPathHistoryService? history,
  })  : tracker = tracker ?? InboxBoosterTrackerService.instance,
        history = history ?? BoosterPathHistoryService.instance;

  static final BoosterLessonStatusService instance =
      BoosterLessonStatusService();

  Future<BoosterLessonStatus> getStatus(TheoryMiniLessonNode lesson) async {
    final interaction = await tracker.getInteractionStats();
    final stats = interaction[lesson.id];
    final shows = (stats?['shows'] as num?)?.toInt() ?? 0;
    final clicks = (stats?['clicks'] as num?)?.toInt() ?? 0;

    String? tag;
    if (lesson.tags.isNotEmpty) {
      tag = lesson.tags.first.trim().toLowerCase();
      if (tag.isEmpty) tag = null;
    }
    final logs = tag != null
        ? await history.getHistory(tag: tag)
        : <BoosterPathLogEntry>[];
    final completed = logs.where((e) => e.completedAt != null).length;
    final hasProgress = logs.isNotEmpty;

    if (shows >= 5 && clicks == 0 && completed == 0) {
      return BoosterLessonStatus.skipped;
    }
    if (completed >= 2) {
      return BoosterLessonStatus.repeated;
    }
    if ((shows > 0 || hasProgress || clicks > 0) && completed == 0) {
      return BoosterLessonStatus.inProgress;
    }
    return BoosterLessonStatus.newLesson;
  }
}
