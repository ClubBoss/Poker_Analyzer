import 'package:flutter/material.dart';

import '../../models/theory_mini_lesson_node.dart';
import '../../services/mini_lesson_library_service.dart';
import '../../screens/theory_lesson_viewer_screen.dart';
import '../../services/analytics_service.dart';

/// Displays a small badge linking to a relevant theory lesson for given tags.
///
/// The badge is only shown if at least one lesson matches [tags]. Lessons are
/// resolved lazily to avoid upfront loading costs.
class InlineTheoryBadge extends StatefulWidget {
  final List<String> tags;
  final String spotId;

  const InlineTheoryBadge({
    super.key,
    required this.tags,
    required this.spotId,
  });

  @override
  State<InlineTheoryBadge> createState() => _InlineTheoryBadgeState();
}

class _InlineTheoryBadgeState extends State<InlineTheoryBadge> {
  late final Future<TheoryMiniLessonNode?> _lessonFuture;

  @override
  void initState() {
    super.initState();
    _lessonFuture = _loadLesson();
  }

  Future<TheoryMiniLessonNode?> _loadLesson() async {
    final library = MiniLessonLibraryService.instance;
    await library.loadAll();
    final lessons = library.findByTags(widget.tags);
    if (lessons.isEmpty) return null;
    return lessons.first;
  }

  void _openLesson(TheoryMiniLessonNode lesson) {
    AnalyticsService.instance.logEvent('theory_link_opened', {
      'lesson_id': lesson.id,
      'spot_id': widget.spotId,
    });
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.9,
        child: TheoryLessonViewerScreen(
          lesson: lesson,
          currentIndex: 1,
          totalCount: 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<TheoryMiniLessonNode?>(
      future: _lessonFuture,
      builder: (context, snapshot) {
        final lesson = snapshot.data;
        if (lesson == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(right: 4.0),
          child: ActionChip(
            avatar: const Icon(Icons.school, size: 16),
            label: const Text('Theory'),
            onPressed: () => _openLesson(lesson),
          ),
        );
      },
    );
  }
}

