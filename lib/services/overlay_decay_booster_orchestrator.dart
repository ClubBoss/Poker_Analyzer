import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/theory_mini_lesson_node.dart';
import '../screens/theory_lesson_viewer_screen.dart';
import 'app_usage_tracker.dart';
import 'inbox_booster_service.dart';
import 'mini_lesson_library_service.dart';
import 'mini_lesson_progress_tracker.dart';
import 'theory_tag_decay_tracker.dart';

/// Surfaces overlay prompts to review decayed theory tags during navigation.
class OverlayDecayBoosterOrchestrator {
  final TheoryTagDecayTracker decay;
  final MiniLessonLibraryService lessons;
  final MiniLessonProgressTracker progress;
  final InboxBoosterService inbox;
  final AppUsageTracker usage;
  final double threshold;
  final Duration recency;
  final Duration idleThreshold;

  OverlayDecayBoosterOrchestrator({
    TheoryTagDecayTracker? decay,
    MiniLessonLibraryService? lessons,
    MiniLessonProgressTracker? progress,
    InboxBoosterService? inbox,
    AppUsageTracker? usage,
    this.threshold = 55,
    this.recency = const Duration(days: 7),
    this.idleThreshold = const Duration(minutes: 2),
  }) : decay = decay ?? TheoryTagDecayTracker(),
       lessons = lessons ?? MiniLessonLibraryService.instance,
       progress = progress ?? MiniLessonProgressTracker.instance,
       inbox = inbox ?? InboxBoosterService.instance,
       usage = usage ?? AppUsageTracker.instance;

  static final OverlayDecayBoosterOrchestrator instance =
      OverlayDecayBoosterOrchestrator();

  static const _lastKey = 'overlay_decay_last';

  /// Shows a prompt if a highly decayed tag is detected.
  Future<void> maybeShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final lastStr = prefs.getString(_lastKey);
    final last = lastStr != null ? DateTime.tryParse(lastStr) : null;
    if (last != null && now.difference(last) < const Duration(days: 1)) return;

    final lesson = await findCandidateLesson(now: now);
    if (lesson == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final controller = messenger.showSnackBar(
      SnackBar(
        content: const Text('This concept might be fading - want to refresh?'),
        action: SnackBarAction(
          label: 'Review now',
          onPressed: () async {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TheoryLessonViewerScreen(
                  lesson: lesson,
                  currentIndex: 1,
                  totalCount: 1,
                ),
              ),
            );
          },
        ),
        duration: const Duration(seconds: 8),
      ),
    );
    controller.closed.then((reason) {
      if (reason != SnackBarClosedReason.action) {
        unawaited(inbox.addReminder(lesson.id));
      }
    });
    await prefs.setString(_lastKey, now.toIso8601String());
  }

  /// Shows a prompt if idle time exceeds [idleThreshold].
  Future<void> maybeShowIfIdle(BuildContext context) async {
    final idle = await usage.idleDuration();
    if (idle < idleThreshold) return;
    await maybeShow(context);
  }

  /// Finds a lesson for the most decayed tag above [threshold].
  Future<TheoryMiniLessonNode?> findCandidateLesson({DateTime? now}) async {
    final scores = await decay.computeDecayScores(now: now);
    final entries = scores.entries.where((e) => e.value > threshold).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) return null;

    await lessons.loadAll();
    final current = now ?? DateTime.now();
    for (final entry in entries) {
      final tag = entry.key;
      final list = lessons.findByTags([tag]);
      for (final lesson in list) {
        final ts = await progress.lastViewed(lesson.id);
        if (ts != null && current.difference(ts) < recency) continue;
        return lesson;
      }
    }
    return null;
  }
}
