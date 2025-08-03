import 'package:flutter/material.dart';

import '../models/theory_mini_lesson_node.dart';
import '../screens/mini_lesson_screen.dart';
import '../services/mini_lesson_library_service.dart';

/// Renders a tappable chip linking to a [TheoryMiniLessonNode] resolved by tag.
///
/// If [theoryTag] is `null` or no lesson is found, renders an empty widget.
class InlineTheoryLinker extends StatelessWidget {
  final String? theoryTag;
  final MiniLessonLibraryService library;
  final void Function(TheoryMiniLessonNode lesson)? onTap;

  const InlineTheoryLinker({
    super.key,
    required this.theoryTag,
    MiniLessonLibraryService? library,
    this.onTap,
  }) : library = library ?? MiniLessonLibraryService.instance;

  @override
  Widget build(BuildContext context) {
    final tag = theoryTag;
    if (tag == null) return const SizedBox.shrink();
    final lessons = library.getByTags({tag});
    if (lessons.isEmpty) return const SizedBox.shrink();
    final lesson = lessons.first;
    return ActionChip(
      avatar: const Icon(Icons.school, size: 16),
      label: Text('Theory: ${lesson.title}'),
      onPressed: () {
        final handler = onTap;
        if (handler != null) {
          handler(lesson);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MiniLessonScreen(lesson: lesson),
            ),
          );
        }
      },
    );
  }
}
