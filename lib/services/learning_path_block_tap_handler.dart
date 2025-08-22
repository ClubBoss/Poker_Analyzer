import 'package:flutter/material.dart';

import '../models/learning_path_block.dart';
import '../screens/mini_lesson_screen.dart';
import '../screens/training_pack_preview_screen.dart';
import 'mini_lesson_library_service.dart';
import 'booster_library_service.dart';

/// Handles taps on [LearningPathBlock]s and opens the correct screen.
class LearningPathBlockTapHandler {
  final MiniLessonLibraryService lessons;
  final BoosterLibraryService boosters;

  LearningPathBlockTapHandler({
    this.lessons = MiniLessonLibraryService.instance,
    this.boosters = BoosterLibraryService.instance,
  });

  /// Opens the appropriate screen for [block].
  Future<void> handleTap(BuildContext context, LearningPathBlock block) async {
    await lessons.loadAll();
    final lesson = lessons.getById(block.lessonId);
    if (lesson != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: lesson)),
      );
      return;
    }

    await boosters.loadAll();
    final booster = boosters.getById(block.lessonId);
    if (booster != null) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrainingPackPreviewScreen(template: booster),
        ),
      );
    }
  }
}
