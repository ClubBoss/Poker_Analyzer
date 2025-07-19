import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v3/lesson_step.dart';
import '../models/v3/lesson_track.dart';
import '../services/lesson_loader_service.dart';
import '../services/lesson_progress_service.dart';
import '../services/lesson_progress_tracker_service.dart';
import '../services/lesson_path_progress_service.dart';
import '../services/learning_track_engine.dart';
import 'lesson_step_screen.dart';
import 'track_selector_screen.dart';

class LessonPathScreen extends StatefulWidget {
  const LessonPathScreen({super.key});

  @override
  State<LessonPathScreen> createState() => _LessonPathScreenState();
}

class _LessonPathScreenState extends State<LessonPathScreen> {
  late Future<List<dynamic>> _future;
  LessonTrack? _track;
  Map<String, bool> _stepProgress = {};

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<dynamic>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('lesson_selected_track');
    if (id == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const TrackSelectorScreen()),
          );
        }
      });
      return <dynamic>[];
    }
    _track = const LearningTrackEngine()
        .getTracks()
        .firstWhereOrNull((t) => t.id == id);
    _stepProgress =
        await LessonProgressTrackerService.instance.getCompletedSteps();
    return Future.wait([
      LessonLoaderService.instance.loadAllLessons(),
      LessonProgressService.instance.getCompletedSteps(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final allSteps = data != null ? data[0] as List<LessonStep> : null;
        final completed = data != null ? data[1] as Set<String> : <String>{};
        final steps = allSteps
            ?.where((s) => _track?.stepIds.contains(s.id) ?? false)
            .toList();
        return Scaffold(
          appBar: AppBar(title: const Text('Учебный путь')),
          backgroundColor: const Color(0xFF121212),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : (steps == null || steps.isEmpty)
                  ? const Center(
                      child: Text(
                        'Нет шагов',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : Column(
                      children: [
                        FutureBuilder<LessonPathProgress>(
                          future: LessonPathProgressService.instance
                              .computeProgress(),
                          builder: (context, progressSnapshot) {
                            final progress = progressSnapshot.data;
                            if (progress == null || progress.total == 0) {
                              return const SizedBox.shrink();
                            }
                            final percentInt = progress.percent.round();
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Прогресс: $percentInt%',
                                    style:
                                        const TextStyle(color: Colors.white),
                                  ),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: progress.percent / 100,
                                    color: Colors.orange,
                                    backgroundColor: Colors.white24,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        Expanded(
                          child: ListView.builder(
                              itemCount: steps!.length,
                              itemBuilder: (context, index) {
                    final step = steps![index];
                    final intro = step.introText;
                    final preview = intro.length > 100
                        ? '${intro.substring(0, 100)}...'
                        : intro;
                    final firstIncomplete =
                        steps!.indexWhere((s) => !completed.contains(s.id));
                    final isDone = completed.contains(step.id);
                    final trackerDone = _stepProgress[step.id] == true;
                    final completedCount = trackerDone ? 1 : 0;
                    const totalCount = 1;
                    final statusIcon = isDone
                        ? '✅'
                        : (index == firstIncomplete ? '🟡' : '🟢');
                    final buttonLabel = isDone
                        ? 'Открыть'
                        : (index == firstIncomplete ? 'Начать' : 'Продолжить');
                    final Widget progressWidget;
                    if (completedCount == totalCount) {
                      progressWidget = const Icon(Icons.check_circle,
                          color: Colors.green, size: 18);
                    } else {
                      final color = completedCount == 0
                          ? Colors.grey
                          : Colors.orange;
                      progressWidget = Text(
                        '$completedCount / $totalCount',
                        style: TextStyle(color: color),
                      );
                      if (completedCount == 0) {
                        progressWidget = Opacity(
                          opacity: 0.4,
                          child: progressWidget,
                        );
                      }
                    }
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(child: Text('$statusIcon ${step.title}')),
                            const SizedBox(width: 8),
                            progressWidget,
                          ],
                        ),
                        subtitle: Text(
                          preview,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LessonStepScreen(step: step),
                              ),
                            );
                          },
                          child: Text(buttonLabel),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
