import 'package:collection/collection.dart';

import '../models/theory_mini_lesson_node.dart';
import 'decay_booster_reminder_engine.dart';
import 'mini_lesson_library_service.dart';
import 'decay_tag_retention_tracker_service.dart';

/// Injects a short theory reminder before launching a decay booster.
class TheoryBoosterInjectionService {
  final DecayBoosterReminderEngine engine;
  final MiniLessonLibraryService library;
  final DecayTagRetentionTrackerService retention;

  TheoryBoosterInjectionService({
    DecayBoosterReminderEngine? engine,
    MiniLessonLibraryService? library,
    DecayTagRetentionTrackerService? retention,
  })  : engine = engine ?? DecayBoosterReminderEngine(),
        library = library ?? MiniLessonLibraryService.instance,
        retention = retention ?? const DecayTagRetentionTrackerService();

  TheoryMiniLessonNode? _cached;
  String? _tag;

  /// Returns a lesson for the most decayed tag or `null`.
  Future<TheoryMiniLessonNode?> getLesson({DateTime? now}) async {
    if (_cached != null) return _cached;
    final tag = await engine.getTopDecayTag(now: now);
    if (tag == null) return null;
    await library.loadAll();
    final lesson = library.findByTags([tag]).firstOrNull;
    if (lesson != null) {
      _cached = lesson;
      _tag = tag;
    }
    return lesson;
  }

  /// Clears previously returned lesson so it can be injected again later.
  void reset() {
    _cached = null;
    _tag = null;
  }

  /// Tag associated with the last returned lesson.
  String? get currentTag => _tag;
}
