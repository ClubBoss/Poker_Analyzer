import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';
import '../models/v3/lesson_track.dart';
import '../services/learning_track_recommendation_engine.dart';
import '../services/track_mastery_service.dart';
import '../services/tag_mastery_service.dart';
import '../services/lesson_loader_service.dart';
import '../services/lesson_path_progress_service.dart';
import '../screens/lesson_step_screen.dart';
import '../screens/lesson_step_recap_screen.dart';

/// Dashboard widget showing recommended learning tracks.
class NextUpWidget extends StatefulWidget {
  const NextUpWidget({super.key});

  @override
  State<NextUpWidget> createState() => _NextUpWidgetState();
}

class _NextUpWidgetState extends State<NextUpWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _future = _load();
    _future.whenComplete(() => _controller.forward());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _load() async {
    final tagMastery = context.read<TagMasteryService>();
    final engine = LearningTrackRecommendationEngine(
      masteryService: TrackMasteryService(mastery: tagMastery),
    );
    final tracks = await engine.getRecommendedTracks();
    final reasons = <String, String>{};
    for (final t in tracks) {
      reasons[t.id] = await engine.getRecommendationReason(t);
    }
    final progress = await LessonPathProgressService.instance
        .computeTrackProgress();
    return {'tracks': tracks, 'reasons': reasons, 'progress': progress};
  }

  Future<void> _startTrack(LessonTrack track) async {
    final steps = await LessonLoaderService.instance.loadAllLessons();
    final stepId = track.stepIds.isNotEmpty ? track.stepIds.first : null;
    final step = stepId == null
        ? null
        : steps.firstWhereOrNull((s) => s.id == stepId);
    if (!mounted || step == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LessonStepScreen(
          step: step,
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

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
        final tracks = data['tracks'] as List<LessonTrack>;
        if (tracks.isEmpty) return const SizedBox.shrink();
        final reasons = data['reasons'] as Map<String, String>;
        final progress = data['progress'] as Map<String, double>;
        return FadeTransition(
          opacity: _controller,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📈 Рекомендуемое продолжение',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                for (final t in tracks)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.title),
                              Text(
                                reasons[t.id] ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed:
                              progress[t.id] != null && progress[t.id]! > 0
                              ? null
                              : () => _startTrack(t),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                          ),
                          child: const Text('Начать'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
