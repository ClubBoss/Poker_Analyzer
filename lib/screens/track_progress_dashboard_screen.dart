import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v3/lesson_track.dart';
import '../models/v3/lesson_step.dart';
import '../services/learning_track_engine.dart';
import '../services/lesson_loader_service.dart';
import '../services/lesson_path_progress_service.dart';
import '../services/lesson_progress_tracker_service.dart';
import 'lesson_step_screen.dart';
import 'lesson_recap_screen.dart';

class TrackProgressDashboardScreen extends StatefulWidget {
  const TrackProgressDashboardScreen({super.key});

  @override
  State<TrackProgressDashboardScreen> createState() =>
      _TrackProgressDashboardScreenState();
}

class _TrackProgressDashboardScreenState
    extends State<TrackProgressDashboardScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<Map<String, dynamic>> _load() async {
    final tracks = const LearningTrackEngine().getTracks();
    final progress =
        await LessonPathProgressService.instance.computeTrackProgress();
    final completed =
        await LessonProgressTrackerService.instance.getCompletedSteps();
    final steps = await LessonLoaderService.instance.loadAllLessons();
    return {
      'tracks': tracks,
      'progress': progress,
      'completed': completed,
      'steps': steps,
    };
  }

  Future<void> _continueTrack(
      LessonTrack track, Map<String, bool> completed, List<LessonStep> steps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lesson_selected_track', track.id);
    final id = track.stepIds
        .firstWhere((e) => completed[e] != true, orElse: () => track.stepIds.last);
    final step = steps.firstWhereOrNull((s) => s.id == id);
    if (!mounted || step == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonStepScreen(
          step: step,
          onStepComplete: (s) async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LessonRecapScreen(step: s)),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final tracks = data?['tracks'] as List<LessonTrack>? ?? [];
        final progress = data?['progress'] as Map<String, double>? ?? {};
        final completed = data?['completed'] as Map<String, bool>? ?? {};
        final steps = data?['steps'] as List<LessonStep>? ?? [];

        return Scaffold(
          appBar: AppBar(title: const Text('Прогресс треков')),
          backgroundColor: const Color(0xFF121212),
          body: snapshot.connectionState != ConnectionState.done
              ? const Center(child: CircularProgressIndicator())
              : tracks.isEmpty
                  ? const Center(
                      child: Text(
                        'Нет треков',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: tracks.length,
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        final percent = progress[track.id] ?? 0.0;
                        final total = track.stepIds.length;
                        final done =
                            track.stepIds.where((id) => completed[id] == true).length;
                        return Card(
                          color: const Color(0xFF1E1E1E),
                          margin:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            title: Text(track.title),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$done / $total шагов, ${percent.round()}%',
                                  style: const TextStyle(color: Colors.white70),
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: percent / 100,
                                  color: Colors.orange,
                                  backgroundColor: Colors.white24,
                                ),
                              ],
                            ),
                            trailing: ElevatedButton(
                              onPressed: () =>
                                  _continueTrack(track, completed, steps),
                              child: const Text('Продолжить путь'),
                            ),
                          ),
                        );
                      },
                    ),
        );
      },
    );
  }
}
