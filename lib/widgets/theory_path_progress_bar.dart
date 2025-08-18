import 'package:flutter/material.dart';

import '../models/theory_mini_lesson_node.dart';
import '../services/mini_lesson_progress_tracker.dart';

class TheoryPathProgressBar extends StatelessWidget {
  final List<TheoryMiniLessonNode> lessons;
  final bool dense;
  final bool fullWidth;

  const TheoryPathProgressBar({
    super.key,
    required this.lessons,
    this.dense = false,
    this.fullWidth = false,
  });

  Future<_ProgressData> _loadProgress() async {
    final tracker = MiniLessonProgressTracker.instance;
    var done = 0;
    for (final lesson in lessons) {
      if (await tracker.isCompleted(lesson.id)) done++;
    }
    return _ProgressData(done, lessons.length);
  }

  Color _colorFor(double ratio, BuildContext context) {
    if (ratio >= 1.0) return Colors.green;
    if (ratio > 0.0) return Theme.of(context).colorScheme.secondary;
    return Colors.grey;
  }

  String _labelFor(int done, int total) {
    if (dense) {
      final pct = total == 0 ? 0 : ((done / total) * 100).round();
      return '$pct% завершено';
    }
    return 'Завершено $done из $total';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ProgressData>(
      future: _loadProgress(),
      builder: (context, snapshot) {
        final data = snapshot.data ?? _ProgressData(0, lessons.length);
        final ratio = data.total == 0 ? 0.0 : data.done / data.total;
        final color = _colorFor(ratio, context);
        final bar = ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            backgroundColor: Colors.white24,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        );
        final label = Text(
          _labelFor(data.done, data.total),
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        );
        if (dense) {
          return SizedBox(
            width: fullWidth ? double.infinity : null,
            child: Row(
              children: [
                Expanded(child: bar),
                const SizedBox(width: 8),
                label,
              ],
            ),
          );
        }
        return Container(
          width: fullWidth ? double.infinity : null,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [bar, const SizedBox(height: 4), label],
          ),
        );
      },
    );
  }
}

class _ProgressData {
  final int done;
  final int total;
  const _ProgressData(this.done, this.total);
}
