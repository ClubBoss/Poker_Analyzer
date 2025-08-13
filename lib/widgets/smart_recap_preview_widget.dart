import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/smart_recap_banner_controller.dart';
import '../models/theory_mini_lesson_node.dart';
import '../screens/mini_lesson_screen.dart';

/// Small widget previewing an upcoming smart recap lesson.
class SmartRecapPreviewWidget extends StatefulWidget {
  const SmartRecapPreviewWidget({super.key});

  @override
  State<SmartRecapPreviewWidget> createState() =>
      _SmartRecapPreviewWidgetState();
}

class _SmartRecapPreviewWidgetState extends State<SmartRecapPreviewWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  TheoryMiniLessonNode? _lesson;
  late SmartRecapBannerController _banner;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    WidgetsBinding.instance.addPostFrameCallback((_) => _setup());
  }

  @override
  void dispose() {
    _banner.removeListener(_onChanged);
    _controller.dispose();
    super.dispose();
  }

  void _setup() {
    _banner = context.read<SmartRecapBannerController>();
    _banner.addListener(_onChanged);
    _onChanged();
  }

  void _onChanged() {
    final lesson = _banner.getPendingLesson();
    if (lesson != null) {
      _lesson = lesson;
      _controller.forward();
    } else {
      _lesson = null;
      _controller.reverse();
    }
    if (mounted) setState(() {});
  }

  void _openLesson() {
    final lesson = _lesson;
    if (lesson == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MiniLessonScreen(
          lesson: lesson,
          recapTag: 'recap',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;
    if (lesson == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return SizeTransition(
      sizeFactor: _controller,
      axisAlignment: -1,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.resolvedTitle,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Рекомендовано к повторению',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _openLesson,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Повторить'),
            ),
          ],
        ),
      ),
    );
  }
}
