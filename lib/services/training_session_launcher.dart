import 'package:flutter/material.dart';

import '../main.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_v2.dart';
import '../screens/training_session_screen.dart';
import '../screens/theory_pack_preview_screen.dart';
import 'achievements_engine.dart';
import 'dart:async';
import '../models/theory_mini_lesson_node.dart';
import 'smart_recap_booster_launcher.dart';
import 'smart_recap_booster_linker.dart';
import 'training_pack_template_storage_service.dart';
import 'pack_recall_stats_service.dart';
import '../core/training/library/training_pack_library_v2.dart';
import 'mini_lesson_library_service.dart';
import '../screens/mini_lesson_screen.dart';

/// Helper to start a training session from a pack template.
class TrainingSessionLauncher {
  const TrainingSessionLauncher();

  /// Launches a training session for [template]. If the pack only contains
  /// theory spots, shows [TheoryPackPreviewScreen] first.
  Future<void> launch(
    TrainingPackTemplateV2 template, {
    int startIndex = 0,
    List<String>? sessionTags,
  }) async {
    final ctx = navigatorKey.currentContext;
    if (ctx == null) return;

    String? lessonId;
    if (template.id == TrainingPackLibraryV2.mvpPackId) {
      lessonId = 'lesson_push_fold_intro';
    } else if (template.id == 'push_fold_btn_cash') {
      lessonId = 'lesson_push_fold_btn_cash';
    }

    if (lessonId != null) {
      await MiniLessonLibraryService.instance.loadAll();
      final lesson = MiniLessonLibraryService.instance.getById(lessonId);
      if (lesson != null) {
        await Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: lesson)),
        );
      }
    }

    unawaited(
      PackRecallStatsService.instance.recordReview(template.id, DateTime.now()),
    );

    if (template.spots.every((s) => s.type == 'theory')) {
      await Navigator.push(
        ctx,
        MaterialPageRoute(
          builder: (_) => TheoryPackPreviewScreen(template: template),
        ),
      );
      unawaited(AchievementsEngine.instance.checkAll());
      return;
    }

    final pack = TrainingPackV2.fromTemplate(template, template.id);
    await Navigator.push(
      ctx,
      MaterialPageRoute(
        builder: (_) =>
            TrainingSessionScreen(pack: pack, startIndex: startIndex),
      ),
    );
    unawaited(AchievementsEngine.instance.checkAll());
  }

  /// Finds and launches a booster drill relevant to [lesson].
  Future<void> launchForMiniLesson(
    TheoryMiniLessonNode lesson, {
    List<String>? sessionTags,
  }) async {
    final service = SmartRecapBoosterLauncher(
      linker: SmartRecapBoosterLinker(
        storage: TrainingPackTemplateStorageService(),
      ),
    );
    await service.launchBoosterForLesson(lesson, sessionTags: sessionTags);
  }
}
