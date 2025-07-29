import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/theory_mini_lesson_node.dart';
import '../models/theory_cluster_summary.dart';
import '../models/booster_backlink.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/tag_mastery_service.dart';
import '../services/booster_pack_launcher.dart';
import '../screens/mini_lesson_screen.dart';
import '../screens/theory_recap_screen.dart';

/// Handles navigation after completing a [TheoryMiniLessonNode].
class TheoryExitHandler {
  const TheoryExitHandler._();

  /// Routes the user based on lesson completion context.
  static Future<void> handleExit(
    BuildContext context,
    TheoryMiniLessonNode node, {
    TheoryClusterSummary? cluster,
    // ignore: avoid-unused-parameters
    dynamic skillMapStatus,
    BoosterBacklink? backlink,
  }) async {
    final nextId = node.nextIds.isNotEmpty ? node.nextIds.first : null;
    if (nextId != null) {
      await MiniLessonLibraryService.instance.loadAll();
      final next = MiniLessonLibraryService.instance.getById(nextId);
      if (next != null) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: next)),
        );
        return;
      }
    }

    if (backlink != null) {
      final mastery = context.read<TagMasteryService>();
      final launcher = BoosterPackLauncher(mastery: mastery);
      await launcher.launchBooster(context);
    }

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => TheoryRecapScreen(
          lesson: node,
          cluster: cluster,
        ),
      ),
    );
  }
}
