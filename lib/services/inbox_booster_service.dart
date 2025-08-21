import 'dart:async';

import '../models/theory_mini_lesson_node.dart';
import 'decay_topic_suppressor_service.dart';
import 'inbox_booster_tracker_service.dart';
import 'mini_lesson_library_service.dart';

/// Simple helper that queues boosters for inbox delivery.
class InboxBoosterService {
  final InboxBoosterTrackerService tracker;
  final MiniLessonLibraryService lessons;

  InboxBoosterService({
    InboxBoosterTrackerService? tracker,
    MiniLessonLibraryService? lessons,
  }) : tracker = tracker ?? InboxBoosterTrackerService.instance,
       lessons = lessons ?? MiniLessonLibraryService.instance;

  static final InboxBoosterService instance = InboxBoosterService();

  /// Adds [lesson] to the inbox queue if not already present.
  Future<void> inject(TheoryMiniLessonNode lesson) async {
    String tag = '';
    if (lesson.tags.isNotEmpty) {
      tag = lesson.tags.first.trim().toLowerCase();
    }
    if (tag.isNotEmpty &&
        await DecayTopicSuppressorService.instance.shouldSuppress(tag)) {
      return;
    }
    await tracker.addToInbox(lesson.id);
    if (tag.isNotEmpty) {
      unawaited(DecayTopicSuppressorService.instance.recordIgnored(tag));
    }
  }

  /// Adds [lessonId] to the inbox queue as a reminder.
  Future<void> addReminder(String lessonId) async {
    final lesson = lessons.getById(lessonId);
    String tag = '';
    if (lesson != null && lesson.tags.isNotEmpty) {
      tag = lesson.tags.first.trim().toLowerCase();
    }
    if (tag.isNotEmpty &&
        await DecayTopicSuppressorService.instance.shouldSuppress(tag)) {
      return;
    }
    await tracker.addToInbox(lessonId);
    if (tag.isNotEmpty) {
      unawaited(DecayTopicSuppressorService.instance.recordIgnored(tag));
    }
  }
}
