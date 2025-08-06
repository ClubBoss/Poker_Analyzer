import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/theory_mini_lesson_node.dart';
import '../models/theory_cluster_summary.dart';
import '../models/booster_backlink.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/tag_mastery_service.dart';
import '../services/booster_pack_launcher.dart';
import '../services/theory_session_service.dart';
import '../screens/theory_lesson_viewer_screen.dart';
import '../screens/theory_recap_screen.dart';
import '../services/skill_tree_library_service.dart';
import '../services/skill_tree_unlock_evaluator.dart';
import '../services/theory_lesson_unlock_notification_service.dart';

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
    final session = TheorySessionService();
    final boosterRec = await session.onComplete(node);
    final ids = await _getUnlockedTheoryLessonIds();
    await TheoryLessonUnlockNotificationService().checkAndNotify(ids, context);
    final nextId = node.nextIds.isNotEmpty ? node.nextIds.first : null;
    if (nextId != null) {
      await MiniLessonLibraryService.instance.loadAll();
      final next = MiniLessonLibraryService.instance.getById(nextId);
      if (next != null) {
        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TheoryLessonViewerScreen(
              lesson: next,
              currentIndex: 1,
              totalCount: 1,
            ),
          ),
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
          boosterRecommendation: boosterRec,
        ),
      ),
    );
  }

  static Future<List<String>> _getUnlockedTheoryLessonIds() async {
    try {
      if (SkillTreeLibraryService.instance.getAllTracks().isEmpty) {
        await SkillTreeLibraryService.instance.reload();
      }
      final eval = const SkillTreeUnlockEvaluator();
      final ids = <String>{};
      for (final res in SkillTreeLibraryService.instance.getAllTracks()) {
        final nodes = eval.getUnlockedNodes(res.tree);
        for (final n in nodes) {
          if (n.theoryLessonId.isNotEmpty) ids.add(n.theoryLessonId);
        }
      }
      return ids.toList();
    } catch (_) {
      return [];
    }
  }
}
