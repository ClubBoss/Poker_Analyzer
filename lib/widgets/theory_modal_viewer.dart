import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../models/theory_mini_lesson_node.dart';

/// Simple modal viewer for [TheoryMiniLessonNode] content.
class TheoryModalViewer extends StatelessWidget {
  final TheoryMiniLessonNode lesson;
  const TheoryModalViewer({super.key, required this.lesson});

  static Future<void> show(BuildContext context, TheoryMiniLessonNode lesson) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.9,
        child: TheoryModalViewer(lesson: lesson),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = MarkdownStyleSheet.fromTheme(theme);
    return SafeArea(
      child: Column(
        children: [
          AppBar(title: Text(lesson.resolvedTitle)),
          Expanded(
            child: Markdown(data: lesson.resolvedContent, styleSheet: style),
          ),
        ],
      ),
    );
  }
}
