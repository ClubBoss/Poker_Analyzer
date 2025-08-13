import 'package:flutter/foundation.dart';

import '../models/theory_mini_lesson_node.dart';
import 'learning_graph_engine.dart';
import 'mini_lesson_booster_engine.dart';
import 'mini_lesson_library_service.dart';
import 'tag_mastery_service.dart';
import 'theory_reinforcement_log_service.dart';
import 'session_log_service.dart';
import 'training_session_service.dart';

/// Automatically injects targeted mini lessons before the current node
/// based on recent weak tags.
class MiniLessonAutoInjector {
  final MiniLessonLibraryService library;
  final MiniLessonBoosterEngine injector;
  final TagMasteryService masteryService;
  final LearningPathEngine engine;
  final TheoryReinforcementLogService logService;

  MiniLessonAutoInjector({
    MiniLessonLibraryService? library,
    MiniLessonBoosterEngine? injector,
    TagMasteryService? masteryService,
    LearningPathEngine? engine,
    TheoryReinforcementLogService? logService,
  })  : library = library ?? MiniLessonLibraryService.instance,
        injector = injector ?? const MiniLessonBoosterEngine(),
        masteryService = masteryService ??
            TagMasteryService(
              logs: SessionLogService(sessions: TrainingSessionService()),
            ),
        engine = engine ?? LearningPathEngine.instance,
        logService = logService ?? TheoryReinforcementLogService.instance;

  static final MiniLessonAutoInjector instance = MiniLessonAutoInjector();

  /// Schedules up to [max] mini lessons matching [weakTags] before the
  /// current node when appropriate.
  Future<void> injectMiniLessonsIfNeeded(
    List<String> weakTags, {
    int max = 1,
    Duration cooldown = const Duration(hours: 12),
  }) async {
    if (weakTags.isEmpty || max <= 0) return;
    final current = engine.getCurrentNode();
    if (current == null) return;

    final tagSet = {for (final t in weakTags) t.trim().toLowerCase()}
      ..removeWhere((e) => e.isEmpty);
    if (tagSet.isEmpty) return;

    await library.loadAll();
    final mastery = await masteryService.computeMastery();

    final lessons = library.getByTags(tagSet);
    if (lessons.isEmpty) return;

    final nodes = engine.engine?.allNodes ?? [];
    final existing = {for (final n in nodes) n.id};
    final recent = await logService.getRecent(within: cooldown);
    final recentIds = {
      for (final l in recent)
        if (l.type == 'mini') l.id
    };

    int overlap(TheoryMiniLessonNode l) =>
        l.tags.where((t) => tagSet.contains(t.toLowerCase())).length;
    double masteryScore(TheoryMiniLessonNode l) {
      double m = 1.0;
      for (final t in l.tags) {
        final val = mastery[t.toLowerCase()] ?? 1.0;
        if (val < m) m = val;
      }
      return m;
    }

    lessons.sort((a, b) {
      final ov = overlap(b).compareTo(overlap(a));
      if (ov != 0) return ov;
      return masteryScore(a).compareTo(masteryScore(b));
    });

    final toInject = <TheoryMiniLessonNode>[];
    for (final l in lessons) {
      if (toInject.length >= max) break;
      if (existing.contains(l.id)) continue;
      if (recentIds.contains(l.id)) continue;
      toInject.add(l);
    }
    if (toInject.isEmpty) return;

    for (final mini in toInject) {
      try {
        await injector.injectBefore(current.id, mini.tags, max: 1);
        await logService.logInjection(mini.id, 'mini', 'auto');
      } catch (e) {
        debugPrint('MiniLessonAutoInjector error: $e');
      }
    }
  }
}
