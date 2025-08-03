import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/theory_mini_lesson_node.dart';
import '../services/recap_completion_tracker.dart';
import '../services/theory_streak_service.dart';
import '../services/theory_booster_recall_engine.dart';
import '../services/pinned_learning_service.dart';
import '../services/mini_lesson_completion_tracker_service.dart';

/// Simple viewer for a [TheoryMiniLessonNode].
class MiniLessonScreen extends StatefulWidget {
  final TheoryMiniLessonNode lesson;
  final String? recapTag;
  final int? initialPosition;
  const MiniLessonScreen({
    super.key,
    required this.lesson,
    this.recapTag,
    this.initialPosition,
  });

  @override
  State<MiniLessonScreen> createState() => _MiniLessonScreenState();
}

class _MiniLessonScreenState extends State<MiniLessonScreen> {
  late DateTime _started;
  late final ScrollController _controller;
  bool _pinned = false;

  @override
  void initState() {
    super.initState();
    _started = DateTime.now();
    _controller = ScrollController(
      initialScrollOffset: (widget.initialPosition ?? 0).toDouble(),
    );
    _pinned =
        PinnedLearningService.instance.isPinned('lesson', widget.lesson.id);
    PinnedLearningService.instance.addListener(_updatePinned);
    unawaited(
      PinnedLearningService.instance.recordOpen('lesson', widget.lesson.id),
    );
    unawaited(
      TheoryBoosterRecallEngine.instance.recordLaunch(widget.lesson.id),
    );
  }

  void _updatePinned() {
    final pinned =
        PinnedLearningService.instance.isPinned('lesson', widget.lesson.id);
    if (pinned != _pinned) setState(() => _pinned = pinned);
  }

  Future<void> _togglePinned() async {
    await PinnedLearningService.instance
        .toggle('lesson', widget.lesson.id);
    final pinned =
        PinnedLearningService.instance.isPinned('lesson', widget.lesson.id);
    setState(() => _pinned = pinned);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(pinned ? 'Pinned' : 'Unpinned')),
    );
  }

  @override
  void dispose() {
    final tag = widget.recapTag;
    if (tag != null) {
      final duration = DateTime.now().difference(_started);
      unawaited(
        RecapCompletionTracker.instance
            .logCompletion(widget.lesson.id, tag, duration),
      );
      unawaited(TheoryStreakService.instance.recordToday());
    }
    PinnedLearningService.instance
        .setLastPosition('lesson', widget.lesson.id, _controller.offset.round());
    _controller.dispose();
    PinnedLearningService.instance.removeListener(_updatePinned);
    unawaited(MiniLessonCompletionTrackerService.instance
        .markCompleted(widget.lesson.id));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.resolvedTitle),
        actions: [
          IconButton(
            icon: Icon(
                _pinned ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: _togglePinned,
          ),
        ],
      ),
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Markdown(
          controller: _controller,
          data: widget.lesson.resolvedContent,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
        ),
      ),
    );
  }
}
