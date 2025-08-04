import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../models/theory_mini_lesson_node.dart';
import '../services/inline_theory_linker_service.dart';
import '../services/theory_lesson_completion_logger.dart';
import '../screens/mini_lesson_screen.dart';
import '../services/review_scheduler_service.dart';

class TheoryQuickAccessBannerWidget extends StatefulWidget {
  final List<String> tags;
  const TheoryQuickAccessBannerWidget({super.key, required this.tags});

  @override
  State<TheoryQuickAccessBannerWidget> createState() =>
      _TheoryQuickAccessBannerWidgetState();
}

class _TheoryQuickAccessBannerWidgetState
    extends State<TheoryQuickAccessBannerWidget> {
  final _linker = InlineTheoryLinkerService();
  TheoryMiniLessonNode? _lesson;
  bool _loading = true;
  bool _isReview = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TheoryQuickAccessBannerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(oldWidget.tags, widget.tags)) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _lesson = null;
      _isReview = false;
    });
    final lessons = await _linker.extractRelevantLessons(widget.tags);
    for (final l in lessons) {
      final completed =
          await TheoryLessonCompletionLogger.instance.isCompleted(l.id);
      if (!completed) {
        _lesson = l;
        _isReview = false;
        break;
      }
      final due =
          await ReviewSchedulerService.instance.isDueForReview(l.id);
      if (due) {
        _lesson = l;
        _isReview = true;
        break;
      }
    }
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }

  void _openLesson() {
    final lesson = _lesson;
    if (lesson == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: lesson)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _lesson == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.lightBlueAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.school, color: Colors.lightBlueAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _lesson!.resolvedTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isReview ? 'Повторение' : 'Новая концепция',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _openLesson,
            child: const Text('Изучить'),
          ),
        ],
      ),
    );
  }
}

