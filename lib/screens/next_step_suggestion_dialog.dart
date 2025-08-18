import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:provider/provider.dart';

import '../models/v3/lesson_step.dart';
import '../models/v3/lesson_track.dart';
import '../services/lesson_path_progress_service.dart';
import '../services/lesson_loader_service.dart';
import '../services/training_pack_template_storage_service.dart';
import '../services/smart_review_service.dart';
import '../services/learning_path_advisor.dart';
import 'lesson_step_screen.dart';

class NextStepSuggestionDialog extends StatelessWidget {
  final LessonStep step;
  final LessonTrack? track;
  const NextStepSuggestionDialog({super.key, required this.step, this.track});

  static Future<void> show(BuildContext context) async {
    final path = LessonPathProgressService.instance;
    final tracks = path.getTracks();
    final steps = await LessonLoaderService.instance.loadAllLessons();
    final completed = await path.getCompletedStepMap();
    final templates = context.read<TrainingPackTemplateStorageService>();
    final profile = await SmartReviewService.instance.getMistakeProfile(
      templates,
    );
    final advisor = LearningPathAdvisor(steps: steps);
    final next = advisor.recommendNextStep(
      availableTracks: tracks,
      completedSteps: completed,
      profile: profile,
    );
    if (next == null) {
      await showDialog(
        context: context,
        builder: (_) => const AlertDialog(
          title: Text('Next Recommended Step'),
          content: Text("You've completed all current lessons!"),
        ),
      );
      return;
    }
    final track = tracks.firstWhereOrNull((t) => t.stepIds.contains(next.id));
    await showDialog(
      context: context,
      builder: (_) => NextStepSuggestionDialog(step: next, track: track),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final tags =
        (step.meta['tags'] as List?)?.map((e) => e.toString()).toList() ??
        const <String>[];
    return AlertDialog(
      title: const Text('Next Recommended Step'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(step.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          if (track != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                track!.title,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          if (tags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                children: [for (final t in tags) Chip(label: Text(t))],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => LessonStepScreen(step: step)),
            );
          },
          style: ElevatedButton.styleFrom(backgroundColor: accent),
          child: const Text('Start Now'),
        ),
      ],
    );
  }
}
