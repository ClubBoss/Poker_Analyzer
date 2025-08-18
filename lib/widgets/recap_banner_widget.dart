import 'package:flutter/material.dart';

import '../models/theory_mini_lesson_node.dart';
import '../screens/theory_lesson_viewer_screen.dart';
import '../services/smart_recap_event_logger.dart';
import '../services/smart_recap_suggestion_engine.dart';

/// Banner that suggests a recap lesson with start and dismiss actions.
class RecapBannerWidget extends StatefulWidget {
  const RecapBannerWidget({super.key});

  @override
  State<RecapBannerWidget> createState() => _RecapBannerWidgetState();
}

class _RecapBannerWidgetState extends State<RecapBannerWidget> {
  final SmartRecapSuggestionEngine _engine =
      SmartRecapSuggestionEngine.instance;
  final SmartRecapEventLogger _logger = SmartRecapEventLogger();

  TheoryMiniLessonNode? _lesson;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final lesson = await _engine.getBestRecapCandidate();
    if (lesson != null) {
      await _logger.logShown(lesson.id, trigger: 'banner');
    }
    if (mounted) {
      setState(() {
        _lesson = lesson;
        _loading = false;
      });
    }
  }

  Future<void> _startLesson() async {
    final lesson = _lesson;
    if (lesson == null) return;
    await _logger.logTapped(lesson.id, trigger: 'banner');
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TheoryLessonViewerScreen(
          lesson: lesson,
          currentIndex: 1,
          totalCount: 1,
        ),
      ),
    );
    await _logger.logCompleted(lesson.id, trigger: 'banner');
    if (mounted) setState(() => _lesson = null);
  }

  Future<void> _dismiss() async {
    final lesson = _lesson;
    if (lesson == null) return;
    await _logger.logDismissed(lesson.id, trigger: 'banner');
    if (mounted) setState(() => _lesson = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _lesson == null) return const SizedBox.shrink();
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
          Row(
            children: [
              Expanded(
                child: Text(
                  _lesson!.resolvedTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54),
                onPressed: _dismiss,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text('Укрепим знание', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(onPressed: _dismiss, child: const Text('Скрыть')),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _startLesson,
                style: ElevatedButton.styleFrom(backgroundColor: accent),
                child: const Text('Повторить'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
