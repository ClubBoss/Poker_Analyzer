import 'package:flutter/material.dart';

import '../models/theory_block_model.dart';
import '../screens/mini_lesson_screen.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/pack_library_service.dart';
import '../services/pinned_learning_service.dart';
import '../services/user_progress_service.dart';
import '../services/training_session_launcher.dart';
import '../services/theory_track_resume_service.dart';

/// Launches the next appropriate item within a [TheoryBlockModel].
class TheoryBlockLauncher {
  const TheoryBlockLauncher();

  Future<void> launch({
    required BuildContext context,
    required TheoryBlockModel block,
    String? trackId,
  }) async {
    if (trackId != null) {
      await TheoryTrackResumeService.instance
          .saveLastVisitedBlock(trackId, block.id);
    }
    await PinnedLearningService.instance.recordOpen('block', block.id);
    await MiniLessonLibraryService.instance.loadAll();
    final progress = UserProgressService.instance;
    for (final id in block.nodeIds) {
      final done = await progress.isTheoryLessonCompleted(id);
      if (!done) {
        final lesson = MiniLessonLibraryService.instance.getById(id);
        if (lesson != null) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MiniLessonScreen(lesson: lesson),
            ),
          );
        }
        return;
      }
    }
    for (final id in block.practicePackIds) {
      final done = await progress.isPackCompleted(id);
      if (!done) {
        final tpl = await PackLibraryService.instance.getById(id);
        if (tpl != null) {
          await const TrainingSessionLauncher().launch(tpl);
        }
        return;
      }
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Block Completed')));
    }
  }
}
