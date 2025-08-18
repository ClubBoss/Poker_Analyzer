import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/theory_mini_lesson_node.dart';
import '../services/theory_inbox_banner_controller.dart';
import '../services/inbox_booster_tracker_service.dart';
import '../screens/mini_lesson_screen.dart';

/// Simple banner showing a booster lesson suggestion from inbox engine.
class TheoryInboxBanner extends StatefulWidget {
  const TheoryInboxBanner({super.key});

  @override
  State<TheoryInboxBanner> createState() => _TheoryInboxBannerState();
}

class _TheoryInboxBannerState extends State<TheoryInboxBanner> {
  TheoryMiniLessonNode? _lesson;
  late TheoryInboxBannerController _controller;
  bool _recorded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setup());
  }

  void _setup() {
    _controller = context.read<TheoryInboxBannerController>();
    _controller.addListener(_update);
    _update();
  }

  @override
  void dispose() {
    _controller.removeListener(_update);
    super.dispose();
  }

  void _update() {
    _lesson = _controller.getLesson();
    _recorded = false;
    if (mounted) setState(() {});
  }

  Future<void> _open() async {
    final lesson = _lesson;
    if (lesson == null) return;
    await InboxBoosterTrackerService.instance.markClicked(lesson.id);
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: lesson)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;
    if (!_controller.shouldShowInboxBanner() || lesson == null) {
      return const SizedBox.shrink();
    }
    if (!_recorded) {
      InboxBoosterTrackerService.instance.markShown(lesson.id);
      _recorded = true;
    }
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lesson.resolvedTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Missed recap', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _open,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Review now'),
            ),
          ),
        ],
      ),
    );
  }
}
