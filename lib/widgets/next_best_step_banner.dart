import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:collection/collection.dart';

import '../services/lesson_path_progress_service.dart';
import '../services/lesson_loader_service.dart';
import '../services/smart_review_service.dart';
import '../services/learning_path_advisor.dart';
import '../models/v3/lesson_step.dart';
import '../models/v3/lesson_track.dart';
import '../screens/lesson_step_screen.dart';
import '../services/training_pack_template_storage_service.dart';

class NextBestStepBanner extends StatefulWidget {
  const NextBestStepBanner({super.key});

  @override
  State<NextBestStepBanner> createState() => _NextBestStepBannerState();
}

class _NextBestStepBannerState extends State<NextBestStepBanner> {
  late Future<_BannerData?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_BannerData?> _load() async {
    final path = LessonPathProgressService.instance;
    final tracks = path.getTracks();
    final steps = await LessonLoaderService.instance.loadAllLessons();
    final completed = await path.getCompletedStepMap();
    final templates = context.read<TrainingPackTemplateStorageService>();
    final profile = await SmartReviewService.instance.getMistakeProfile(
      templates,
    );

    final advisor = LearningPathAdvisor(steps: steps);
    final step = advisor.recommendNextStep(
      availableTracks: tracks,
      completedSteps: completed,
      profile: profile,
    );
    if (step == null) return null;
    final track = tracks.firstWhereOrNull((t) => t.stepIds.contains(step.id));
    return _BannerData(step: step, track: track);
  }

  void _open(LessonStep step) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LessonStepScreen(step: step)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return FutureBuilder<_BannerData?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final data = snapshot.data;
        if (data == null) return const SizedBox.shrink();
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
              Text(
                '🔁 Next Step: ${data.step.title}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (data.track != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    data.track!.title,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _open(data.step),
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  child: const Text('Continue'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BannerData {
  final LessonStep step;
  final LessonTrack? track;
  const _BannerData({required this.step, required this.track});
}
