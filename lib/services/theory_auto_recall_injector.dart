import 'package:flutter/material.dart';

import '../models/theory_mini_lesson_node.dart';
import '../models/v2/training_pack_spot.dart';
import 'decay_tag_retention_tracker_service.dart';
import 'mini_lesson_library_service.dart';

/// Injects inline theory summaries for review entries with decayed tags.
class TheoryAutoRecallInjector {
  final DecayTagRetentionTrackerService retention;
  final MiniLessonLibraryService lessons;

  const TheoryAutoRecallInjector({
    DecayTagRetentionTrackerService? retention,
    MiniLessonLibraryService? lessons,
  })  : retention = retention ?? const DecayTagRetentionTrackerService(),
        lessons = lessons ?? MiniLessonLibraryService.instance;

  /// Builds a widget that conditionally injects a theory snippet below [entry].
  Widget build(BuildContext context, Object entry) {
    return FutureBuilder<Widget?>(
      future: _maybeBuildSnippet(entry),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return snapshot.data!;
        }
        return const SizedBox.shrink();
      },
    );
  }

  Future<Widget?> _maybeBuildSnippet(Object entry) async {
    final tags = _extractTags(entry);
    if (tags.isEmpty) return null;

    await lessons.loadAll();

    for (final raw in tags) {
      final tag = raw.trim().toLowerCase();
      if (tag.isEmpty) continue;
      if (!await retention.isDecayed(tag)) continue;
      final lessonList = lessons.findByTags([tag]);
      if (lessonList.isEmpty) continue;
      final TheoryMiniLessonNode lesson = lessonList.first;
      final summary = _shortSummary(lesson.resolvedContent);
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Divider(color: Colors.white24, height: 16),
            Text(
              lesson.resolvedTitle,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              summary,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
      );
    }
    return null;
  }

  List<String> _extractTags(Object entry) {
    if (entry is TrainingPackSpot) return entry.tags;
    return const [];
  }

  String _shortSummary(String text, {int max = 160}) {
    final clean = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length <= max) return clean;
    return '${clean.substring(0, max)}…';
  }
}
