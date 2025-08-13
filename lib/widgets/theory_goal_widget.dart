import 'package:flutter/material.dart';
import '../models/theory_goal.dart';
import '../services/tag_mastery_service.dart';
import '../services/mini_lesson_library_service.dart';
import '../services/theory_lesson_progress_tracker.dart';
import '../services/session_log_service.dart';
import '../services/training_session_service.dart';

/// Compact card widget displaying a single [TheoryGoal].
class TheoryGoalWidget extends StatefulWidget {
  final TheoryGoal goal;
  final VoidCallback? onTap;

  const TheoryGoalWidget({
    super.key,
    required this.goal,
    this.onTap,
  });

  @override
  State<TheoryGoalWidget> createState() => _TheoryGoalWidgetState();
}

class _TheoryGoalWidgetState extends State<TheoryGoalWidget> {
  late Future<double> _progressFuture;

  @override
  void initState() {
    super.initState();
    _progressFuture = _loadProgress();
  }

  Future<double> _loadProgress() async {
    final tags = widget.goal.tagOrCluster
        .split(',')
        .map((e) => e.trim().toLowerCase())
        .where((e) => e.isNotEmpty)
        .toList();

    await MiniLessonLibraryService.instance.loadAll();
    final lessons = MiniLessonLibraryService.instance.findByTags(tags);
    if (lessons.isNotEmpty) {
      const tracker = TheoryLessonProgressTracker();
      return tracker.progressForLessons(lessons);
    }

    final mastery = TagMasteryService(
      logs: SessionLogService(sessions: TrainingSessionService()),
    );
    final map = await mastery.computeMastery();
    if (tags.isEmpty) return 0.0;
    double sum = 0;
    var count = 0;
    for (final t in tags) {
      final v = map[t];
      if (v != null) {
        sum += v;
        count++;
      }
    }
    return count == 0 ? 0.0 : sum / count;
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<double>(
      future: _progressFuture,
      builder: (context, snapshot) {
        final progress = snapshot.data ?? 0.0;
        final target = widget.goal.targetProgress.clamp(0.0, 1.0);
        final ratio = target > 0 ? (progress / target).clamp(0.0, 1.0) : 0.0;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.goal.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (widget.goal.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    widget.goal.description,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: Colors.white24,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${(progress * 100).round()}% / ${(target * 100).round()}%',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: widget.onTap,
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  child: const Text('Продолжить'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
