import 'package:flutter/material.dart';

import '../models/learning_path_track_model.dart';
import '../models/learning_path_template_v2.dart';
import 'learning_path_card.dart';

class TrackSectionWidget extends StatelessWidget {
  final LearningPathTrackModel track;
  final List<LearningPathTemplateV2> paths;

  const TrackSectionWidget({
    super.key,
    required this.track,
    required this.paths,
  });

  int _orderOf(LearningPathTemplateV2 p) {
    try {
      final value = (p as dynamic).order;
      if (value is int) return value;
    } catch (_) {}
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    final list = List<LearningPathTemplateV2>.from(paths)
      ..sort((a, b) => _orderOf(a).compareTo(_orderOf(b)));

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              track.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          if (track.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                track.description,
                style: const TextStyle(color: Colors.white70),
              ),
            ),
          if (track.recommendedFor != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                track.recommendedFor!,
                style: TextStyle(color: accent, fontSize: 12),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final p in list)
                  SizedBox(
                    width: 180,
                    child: LearningPathCard(template: p),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
