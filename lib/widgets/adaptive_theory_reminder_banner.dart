import 'package:flutter/material.dart';

import '../models/theory_mini_lesson_node.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/tag_decay_forecast_service.dart';
import '../screens/mini_lesson_screen.dart';

/// Banner suggesting theory mini lessons when related training tags are decaying.
class AdaptiveTheoryReminderBanner extends StatefulWidget {
  const AdaptiveTheoryReminderBanner({super.key});

  @override
  State<AdaptiveTheoryReminderBanner> createState() =>
      _AdaptiveTheoryReminderBannerState();
}

class _AdaptiveTheoryReminderBannerState
    extends State<AdaptiveTheoryReminderBanner> {
  bool _loading = true;
  List<TheoryMiniLessonNode> _lessons = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final decayStats = await const TagDecayForecastService().summarize();
    final tags = <String>[];
    for (final stat in decayStats.values) {
      if (stat.averageInterval > Duration.zero &&
          stat.timeSinceLast > stat.averageInterval) {
        tags.add(stat.tag.toLowerCase());
      }
    }
    await MiniLessonLibraryService.instance.loadAll();
    final found =
        MiniLessonLibraryService.instance.findByTags(tags).take(2).toList();
    if (mounted) {
      setState(() {
        _lessons = found;
        _loading = false;
      });
    }
  }

  void _open(TheoryMiniLessonNode lesson) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MiniLessonScreen(lesson: lesson)),
    );
  }

  void _dismiss() {
    setState(() => _lessons = []);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _lessons.isEmpty) return const SizedBox.shrink();
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
              const Expanded(
                child: Text(
                  'Освежите теорию',
                  style: TextStyle(
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
          for (var i = 0; i < _lessons.length; i++) ...[
            Text(
              _lessons[i].resolvedTitle,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _open(_lessons[i]),
                style: TextButton.styleFrom(foregroundColor: accent),
                child: const Text('Освежить теорию'),
              ),
            ),
            if (i != _lessons.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
