import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/v3/lesson_step.dart';
import '../models/v3/lesson_track.dart';
import '../services/lesson_loader_service.dart';
import '../services/lesson_path_progress_service.dart';
import '../services/learning_path_advisor.dart';
import '../services/smart_review_service.dart';
import '../services/training_pack_template_storage_service.dart';
import '../widgets/streak_banner_widget.dart';
import '../services/lesson_streak_engine.dart';
import '../widgets/daily_training_recap_card.dart';
import 'lesson_step_screen.dart';
import 'track_recap_screen.dart';

class LessonStepRecapScreen extends StatefulWidget {
  final LessonStep step;
  const LessonStepRecapScreen({super.key, required this.step});

  @override
  State<LessonStepRecapScreen> createState() => _LessonStepRecapScreenState();
}

class _ScreenData {
  final LessonStep? next;
  final int mistakes;
  final bool completedTrack;
  final LessonTrack? track;
  const _ScreenData({
    required this.next,
    required this.mistakes,
    required this.completedTrack,
    this.track,
  });
}

class _LessonStepRecapScreenState extends State<LessonStepRecapScreen> {
  late Future<_ScreenData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_ScreenData> _load() async {
    final path = LessonPathProgressService.instance;
    final tracks = path.getTracks();
    final steps = await LessonLoaderService.instance.loadAllLessons();
    final completed = await path.getCompletedStepMap();
    final templates = context.read<TrainingPackTemplateStorageService>();
    final profile = await SmartReviewService.instance.getMistakeProfile(
      templates,
    );
    final spots = await SmartReviewService.instance.getMistakeSpots(templates);
    final advisor = LearningPathAdvisor(steps: steps);
    final next = advisor.recommendNextStep(
      availableTracks: tracks,
      completedSteps: completed,
      profile: profile,
    );
    final prefs = await SharedPreferences.getInstance();
    final selectedId = prefs.getString('lesson_selected_track');
    final track = tracks.firstWhereOrNull((t) => t.id == selectedId);
    bool doneTrack = false;
    if (track != null) {
      final done = completed.values.expand((e) => e).toSet();
      if (track.stepIds.every(done.contains) &&
          widget.step.id == track.stepIds.last) {
        doneTrack = true;
      }
    }
    return _ScreenData(
      next: next,
      mistakes: spots.length,
      completedTrack: doneTrack,
      track: track,
    );
  }

  void _openNext(LessonStep next) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LessonStepScreen(
          step: next,
          onStepComplete: (s) async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LessonStepRecapScreen(step: s)),
            );
          },
        ),
      ),
    );
  }

  void _openTrackRecap(LessonTrack track) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => TrackRecapScreen(track: track)),
    );
  }

  void _backHome() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final tags = (widget.step.meta['tags'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Резюме шага')),
      backgroundColor: const Color(0xFF121212),
      body: FutureBuilder<_ScreenData>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final done = snapshot.connectionState == ConnectionState.done;
          final next = data?.next;
          final mistakes = data?.mistakes ?? 0;
          final completedTrack = data?.completedTrack == true;
          final track = data?.track;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.step.title} \u2014 \u2713 Завершено',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.step.summaryText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    widget.step.summaryText,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
                if (tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: [for (final t in tags) Chip(label: Text(t))],
                  ),
                ],
                if (mistakes > 0) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Ошибок для повторения: $mistakes',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ],
                FutureBuilder<int>(
                  future: LessonStreakEngine.instance.getCurrentStreak(),
                  builder: (context, snapshot) {
                    final streak = snapshot.data ?? 0;
                    if (streak < 2) return const SizedBox.shrink();
                    return const StreakBannerWidget();
                  },
                ),
                const SizedBox(height: 12),
                const DailyTrainingRecapCard(),
                const Spacer(),
                if (!done)
                  const Center(child: CircularProgressIndicator())
                else if (completedTrack && track != null) ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => _openTrackRecap(track),
                      style: ElevatedButton.styleFrom(backgroundColor: accent),
                      child: const Text('Итоги трека'),
                    ),
                  ),
                ] else if (next != null) ...[
                  Text(
                    'Следующий шаг: ${next.title}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => _openNext(next),
                      style: ElevatedButton.styleFrom(backgroundColor: accent),
                      child: const Text('Начать следующий шаг'),
                    ),
                  ),
                ] else ...[
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: _backHome,
                      child: const Text('В меню'),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
