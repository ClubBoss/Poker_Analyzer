import 'package:flutter/material.dart';
import '../../models/v2/training_pack_template.dart';

class RecentTrainingPackSection extends StatelessWidget {
  final List<TrainingPackTemplate> templates;
  final Map<String, int> progress;
  final VoidCallback onClear;
  final void Function(TrainingPackTemplate) onPlay;

  const RecentTrainingPackSection({
    super.key,
    required this.templates,
    required this.progress,
    required this.onClear,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const Text('Recent Packs'),
              const Spacer(),
              TextButton(onPressed: onClear, child: const Text('Clear')),
            ],
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final t in templates)
                _RecentTrainingPackCard(
                  template: t,
                  progress: progress[t.id] ?? 0,
                  onPlay: () => onPlay(t),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentTrainingPackCard extends StatelessWidget {
  final TrainingPackTemplate template;
  final int progress;
  final VoidCallback onPlay;

  const _RecentTrainingPackCard({
    required this.template,
    required this.progress,
    required this.onPlay,
  });

  @override
  Widget build(BuildContext context) {
    final total = template.spots.length;
    final ratio = total == 0 ? 0.0 : (progress.clamp(0, total)) / total;
    return Container(
      width: 160,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(template.name, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: ratio),
          const Spacer(),
          Align(
            alignment: Alignment.bottomRight,
            child: IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: onPlay,
            ),
          ),
        ],
      ),
    );
  }
}
