import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/theory_mini_lesson_node.dart';
import '../services/recap_completion_tracker.dart';

/// Simple viewer for a [TheoryMiniLessonNode].
class MiniLessonScreen extends StatefulWidget {
  final TheoryMiniLessonNode lesson;
  final String? recapTag;
  const MiniLessonScreen({super.key, required this.lesson, this.recapTag});

  @override
  State<MiniLessonScreen> createState() => _MiniLessonScreenState();
}

class _MiniLessonScreenState extends State<MiniLessonScreen> {
  late DateTime _started;

  @override
  void initState() {
    super.initState();
    _started = DateTime.now();
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
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.lesson.resolvedTitle)),
      backgroundColor: const Color(0xFF121212),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Markdown(
          data: widget.lesson.resolvedContent,
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
        ),
      ),
    );
  }
}
