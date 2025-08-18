import 'package:flutter/material.dart';

import '../models/theory_mini_lesson_node.dart';
import '../services/mini_lesson_progress_tracker.dart';

/// Displays completion status for a group of theory lessons.
/// Shows a checkmark when 100% complete, a progress ring when
/// partially done and an empty ring when untouched.
class TheoryClusterCompletionOverlay extends StatelessWidget {
  final List<TheoryMiniLessonNode> lessons;
  final double size;

  const TheoryClusterCompletionOverlay({
    super.key,
    required this.lessons,
    this.size = 20,
  });

  Future<double> _progress() async {
    if (lessons.isEmpty) return 0.0;
    final tracker = MiniLessonProgressTracker.instance;
    var done = 0;
    for (final l in lessons) {
      if (await tracker.isCompleted(l.id)) done++;
    }
    return done / lessons.length;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<double>(
      future: _progress(),
      builder: (context, snapshot) {
        final value = snapshot.data ?? 0.0;
        if (value >= 1.0) {
          return Icon(Icons.check_circle, color: Colors.green, size: size);
        }
        if (value <= 0.0) {
          return Icon(
            Icons.radio_button_unchecked,
            color: Colors.grey,
            size: size,
          );
        }
        final ring = SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: value.clamp(0.0, 1.0),
            strokeWidth: 3,
            backgroundColor: Colors.black26,
            color: Theme.of(context).colorScheme.secondary,
          ),
        );
        final pct = (value * 100).round();
        return Stack(
          alignment: Alignment.center,
          children: [
            ring,
            Text(
              '$pct%',
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.4,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }
}
