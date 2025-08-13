import 'package:flutter/material.dart';

import '../services/lesson_streak_tracker_service.dart';
import '../services/theory_lesson_completion_logger.dart';
import '../services/mini_lesson_library_service.dart';
import '../models/theory_mini_lesson_node.dart';
import '../screens/mini_lesson_screen.dart';

class DailyTrainingRecapCard extends StatefulWidget {
  const DailyTrainingRecapCard({super.key});

  @override
  State<DailyTrainingRecapCard> createState() => _DailyTrainingRecapCardState();
}

class _RecapData {
  final int streak;
  final int completedToday;
  final TheoryMiniLessonNode? next;
  const _RecapData(
      {required this.streak, required this.completedToday, this.next});
}

class _DailyTrainingRecapCardState extends State<DailyTrainingRecapCard> {
  late Future<_RecapData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_RecapData> _load() async {
    final streak = await LessonStreakTrackerService.instance.getCurrentStreak();
    final completed = await TheoryLessonCompletionLogger.instance
        .getCompletionsCountFor(DateTime.now());
    final next = await MiniLessonLibraryService.instance.getNextLesson();
    return _RecapData(streak: streak, completedToday: completed, next: next);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_RecapData>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final data = snapshot.data!;
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Текущий стрик: ${data.streak}',
                  style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              Text('Уроков сегодня: ${data.completedToday}',
                  style: const TextStyle(color: Colors.white)),
              if (data.next != null) ...[
                const SizedBox(height: 8),
                Text('Следующий урок: ${data.next!.resolvedTitle}',
                    style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MiniLessonScreen(lesson: data.next!),
                        ),
                      );
                    },
                    child: const Text('Начать следующий урок'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
