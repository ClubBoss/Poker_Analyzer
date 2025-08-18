import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../models/theory_mini_lesson_node.dart';
import '../models/v2/training_pack_spot.dart';
import 'decay_tag_retention_tracker_service.dart';
import 'mini_lesson_library_service.dart';
import 'recall_boost_interaction_logger.dart';

/// Injects inline theory summaries for review entries with decayed tags.
class TheoryAutoRecallInjector {
  final DecayTagRetentionTrackerService retention;
  final MiniLessonLibraryService lessons;

  const TheoryAutoRecallInjector({
    DecayTagRetentionTrackerService? retention,
    MiniLessonLibraryService? lessons,
  }) : retention = retention ?? const DecayTagRetentionTrackerService(),
       lessons = lessons ?? MiniLessonLibraryService.instance;

  /// Builds a widget that conditionally injects a theory snippet below [entry].
  Widget build(BuildContext context, String nodeId, Object entry) {
    return FutureBuilder<Widget?>(
      future: _maybeBuildSnippet(nodeId, entry),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.data != null) {
          return snapshot.data!;
        }
        return const SizedBox.shrink();
      },
    );
  }

  Future<Widget?> _maybeBuildSnippet(String nodeId, Object entry) async {
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
      return _RecallBoostSnippet(
        tag: tag,
        nodeId: nodeId,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: Colors.white24, height: 16),
              Text(
                lesson.resolvedTitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                summary,
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
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
    return '${clean.substring(0, max)}...';
  }
}

class _RecallBoostSnippet extends StatefulWidget {
  final Widget child;
  final String tag;
  final String nodeId;
  const _RecallBoostSnippet({
    required this.child,
    required this.tag,
    required this.nodeId,
  });

  @override
  State<_RecallBoostSnippet> createState() => _RecallBoostSnippetState();
}

class _RecallBoostSnippetState extends State<_RecallBoostSnippet> {
  DateTime? _visibleAt;
  bool _logged = false;

  void _maybeLog() {
    if (_logged || _visibleAt == null) return;
    final duration = DateTime.now().difference(_visibleAt!).inMilliseconds;
    if (duration >= 1000) {
      _logged = true;
      RecallBoostInteractionLogger.instance.logView(
        widget.tag,
        widget.nodeId,
        duration,
      );
    }
    _visibleAt = null;
  }

  @override
  void dispose() {
    _maybeLog();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: ValueKey('rb_${widget.tag}_${widget.nodeId}'),
      onVisibilityChanged: (info) {
        if (info.visibleFraction > 0) {
          _visibleAt ??= DateTime.now();
        } else {
          _maybeLog();
        }
      },
      child: widget.child,
    );
  }
}
