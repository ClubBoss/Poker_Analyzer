import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/theory_mini_lesson_node.dart';
import '../models/v2/training_pack_template_v2.dart';
import '../models/v2/training_pack_template.dart';
import '../screens/training_session_screen.dart';
import 'training_session_service.dart';
import 'navigation_service.dart';
import 'smart_recap_booster_linker.dart';

/// Launches a booster pack related to a recap lesson when requested by the user.
class SmartRecapBoosterLauncher {
  final SmartRecapBoosterLinker linker;
  final NavigationService navigation;

  const SmartRecapBoosterLauncher({
    required this.linker,
    this.navigation = const NavigationService(),
  });

  /// Opens the best booster pack for [lesson] or shows a fallback dialog.
  Future<void> launchBoosterForLesson(
    TheoryMiniLessonNode lesson, {
    List<String>? sessionTags,
  }) async {
    final ctx = navigation.context;
    if (ctx == null) return;

    final List<TrainingPackTemplateV2> packs = await linker
        .getBoostersForLesson(lesson);
    if (packs.isEmpty) {
      await showDialog<void>(
        context: ctx,
        builder: (_) => const AlertDialog(
          content: Text('Нет тренировок по теме. Попробуйте позже'),
        ),
      );
      return;
    }

    final template = TrainingPackTemplate.fromJson(packs.first.toJson());
    await ctx.read<TrainingSessionService>().startSession(
      template,
      persist: false,
      sessionTags: sessionTags,
    );
    await navigation.push(
      MaterialPageRoute(builder: (_) => const TrainingSessionScreen()),
    );
  }
}
