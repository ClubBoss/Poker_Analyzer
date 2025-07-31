import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/theory_mini_lesson_node.dart';
import '../screens/mini_lesson_screen.dart';
import '../services/booster_recall_banner_engine.dart';

/// Banner suggesting a theory lesson after booster completion.
class BoosterRecallBanner extends StatefulWidget {
  const BoosterRecallBanner({super.key});

  @override
  State<BoosterRecallBanner> createState() => _BoosterRecallBannerState();
}

class _BoosterRecallBannerState extends State<BoosterRecallBanner> {
  TheoryMiniLessonNode? _lesson;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final engine = context.read<BoosterRecallBannerEngine>();
    final lesson = await engine.getSuggestion();
    if (mounted) {
      setState(() {
        _lesson = lesson;
        _loading = false;
      });
    }
  }

  Future<void> _open() async {
    final lesson = _lesson;
    if (lesson == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: lesson)),
    );
    await context.read<BoosterRecallBannerEngine>().dismiss(lesson.id);
    if (mounted) setState(() => _lesson = null);
  }

  Future<void> _dismiss() async {
    final lesson = _lesson;
    if (lesson != null) {
      await context.read<BoosterRecallBannerEngine>().dismiss(lesson.id);
    }
    if (mounted) setState(() => _lesson = null);
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;
    if (_loading || lesson == null) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final title = lesson.tags.isNotEmpty
        ? 'Освежи теорию по теме: ${lesson.tags.first}'
        : 'Освежи теорию';
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
                  title,
                  style: const TextStyle(
                    color: Colors.white,
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
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _open,
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Перейти к уроку'),
            ),
          ),
        ],
      ),
    );
  }
}
