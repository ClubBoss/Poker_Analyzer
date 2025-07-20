import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../models/v3/lesson_step.dart';
import '../models/v3/lesson_track.dart';
import '../services/next_up_engine.dart';
import '../services/track_mastery_service.dart';
import '../services/tag_mastery_service.dart';
import '../services/lesson_loader_service.dart';
import '../services/lesson_path_progress_service.dart';
import '../services/learning_track_engine.dart';
import '../services/yaml_lesson_track_loader.dart';
import '../screens/lesson_step_screen.dart';

/// Banner showing the next recommended lesson step.
class NextUpBanner extends StatefulWidget {
  const NextUpBanner({super.key});

  @override
  State<NextUpBanner> createState() => _NextUpBannerState();
}

class _NextUpBannerState extends State<NextUpBanner>
    with SingleTickerProviderStateMixin {
  static bool _shown = false;
  late final AnimationController _controller;
  LessonTrack? _track;
  LessonStep? _step;
  double _percent = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    if (_shown) {
      _loading = false;
    } else {
      _shown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final tagMastery = context.read<TagMasteryService>();
    final engine = NextUpEngine(
      masteryService: TrackMasteryService(mastery: tagMastery),
    );
    final ref = await engine.getNextRecommendedStep();
    if (ref == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    final steps = await LessonLoaderService.instance.loadAllLessons();
    final builtIn = const LearningTrackEngine().getTracks();
    final yaml = await YamlLessonTrackLoader.instance.loadTracksFromAssets();
    final tracks = [...builtIn, ...yaml];
    final step = steps.firstWhereOrNull((s) => s.id == ref.stepId);
    final track = tracks.firstWhereOrNull((t) => t.id == ref.trackId);
    final progress =
        await LessonPathProgressService.instance.computeTrackProgress();
    final percent = progress[ref.trackId] ?? 0.0;
    if (!mounted) return;
    setState(() {
      _step = step;
      _track = track;
      _percent = percent;
      _loading = false;
    });
    if (step != null) _controller.forward();
  }

  Future<void> _openStep() async {
    final step = _step;
    if (step == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LessonStepScreen(step: step)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_step == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.teal, Colors.blueGrey],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Вы завершили все уроки 🎉',
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    final accent = Theme.of(context).colorScheme.secondary;
    final track = _track;
    final stepIndex = track?.stepIds.indexOf(_step!.id) ?? 0;
    final stepCount = track?.stepIds.length ?? 1;
    final progressLabel =
        'Step ${stepIndex + 1} of $stepCount · ${_percent.toStringAsFixed(0)}% complete';
    return FadeTransition(
      opacity: _controller,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A5AE0), Color(0xFF8E7BFA)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (track != null)
              Text(
                track.title,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 4),
            Text(
              progressLabel,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _openStep,
                style: ElevatedButton.styleFrom(backgroundColor: accent),
                child: const Text('Продолжить'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

