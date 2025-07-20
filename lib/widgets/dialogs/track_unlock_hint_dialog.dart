import 'package:flutter/material.dart';

import '../../models/v3/lesson_track.dart';
import '../../models/track_unlock_requirement_progress.dart';
import '../../services/learning_track_engine.dart';
import '../../services/yaml_lesson_track_loader.dart';
import '../../services/lesson_track_unlock_engine.dart';

class TrackUnlockHintDialog extends StatelessWidget {
  final LessonTrack track;
  final List<TrackUnlockRequirementProgress> requirements;
  const TrackUnlockHintDialog({
    super.key,
    required this.track,
    required this.requirements,
  });

  @override
  Widget build(BuildContext context) {
    final allMet = requirements.isNotEmpty &&
        requirements.every((r) => r.met);
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: Text(track.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(track.description,
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          for (final r in requirements)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text(r.icon, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(child: Text(r.label)),
                  Text(
                    '${r.current}/${r.required}',
                    style: TextStyle(
                        color: r.met ? Colors.green : Colors.red),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    r.met ? Icons.check_circle : Icons.cancel,
                    color: r.met ? Colors.green : Colors.red,
                    size: 16,
                  ),
                ],
              ),
            ),
          if (allMet) ...[
            const SizedBox(height: 8),
            const Text('\uD83D\uDD13 Track will unlock soon!',
                style: TextStyle(color: Colors.greenAccent)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}

Future<void> showTrackUnlockHintDialog(
    BuildContext context, String trackId) async {
  final builtIn = const LearningTrackEngine().getTracks();
  final yaml = await YamlLessonTrackLoader.instance.loadTracksFromAssets();
  final tracks = [...builtIn, ...yaml];
  final track = tracks.firstWhere(
    (t) => t.id == trackId,
    orElse: () =>
        const LessonTrack(id: '', title: '', description: '', stepIds: []),
  );
  final reqs =
      await LessonTrackUnlockEngine.instance.getRequirementProgress(trackId);
  if (context.mounted) {
    await showDialog(
      context: context,
      builder: (_) => TrackUnlockHintDialog(track: track, requirements: reqs),
    );
  }
}
