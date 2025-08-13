import 'package:flutter/material.dart';

import '../models/player_profile.dart';
import '../models/theory_mini_lesson_node.dart';
import '../services/mini_lesson_library_service.dart';
import '../screens/theory_lesson_preview_screen.dart';

/// Handles navigation from cluster map nodes to lesson previews.
class ClusterNodeNavigator {
  const ClusterNodeNavigator._();

  /// Opens the preview for [node] if unlocked, otherwise shows a snack.
  static Future<void> handleTap(
    BuildContext context,
    TheoryMiniLessonNode node,
    PlayerProfile profile,
  ) async {
    final unlocked = await _isUnlocked(node.id, profile);
    if (!unlocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Урок пока недоступен')),
      );
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TheoryLessonPreviewScreen(lessonId: node.id),
      ),
    );
  }

  /// Returns true if the lesson is reachable based on [profile] progress.
  static Future<bool> _isUnlocked(
      String lessonId, PlayerProfile profile) async {
    await MiniLessonLibraryService.instance.loadAll();
    final lessons = MiniLessonLibraryService.instance.all;
    if (lessons.isEmpty) return false;

    final byId = {for (final l in lessons) l.id: l};
    final incoming = {for (final l in lessons) l.id: <String>{}};
    for (final l in lessons) {
      for (final next in l.nextIds) {
        if (incoming.containsKey(next)) incoming[next]!.add(l.id);
      }
    }

    final roots = <String>{};
    for (final l in lessons) {
      if (incoming[l.id]!.isEmpty) roots.add(l.id);
    }
    final queue = <String>[
      if (profile.completedLessonIds.isEmpty)
        ...roots
      else
        ...profile.completedLessonIds.where(byId.containsKey),
    ];
    final reachable = <String>{...queue};
    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      final node = byId[id];
      if (node == null) continue;
      for (final next in node.nextIds) {
        if (!byId.containsKey(next)) continue;
        if (reachable.add(next)) queue.add(next);
      }
    }

    return reachable.contains(lessonId);
  }
}
