import 'package:flutter/material.dart';

import '../models/v2/training_pack_template_v2.dart';

/// Banner that suggests booster packs when applicable.
class BoosterReminderBanner extends StatefulWidget {
  /// Booster packs to recommend.
  final List<TrainingPackTemplateV2> boosters;

  /// Callback when user taps start.
  final void Function(TrainingPackTemplateV2 booster)? onTap;

  const BoosterReminderBanner({
    super.key,
    required this.boosters,
    this.onTap,
  });

  @override
  State<BoosterReminderBanner> createState() => _BoosterReminderBannerState();
}

class _BoosterReminderBannerState extends State<BoosterReminderBanner> {
  bool _hidden = false;

  void _start(TrainingPackTemplateV2 booster) {
    widget.onTap?.call(booster);
  }

  @override
  Widget build(BuildContext context) {
    if (_hidden || widget.boosters.isEmpty) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final boosters = widget.boosters.take(2).toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[850]
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(8),
        boxShadow: kElevationToShadow[2],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '🧠 Booster Reminder',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                onPressed: () => setState(() => _hidden = true),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 140,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) => _boosterCard(boosters[index], accent),
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemCount: boosters.length,
            ),
          ),
        ],
      ),
    );
  }

  Widget _boosterCard(TrainingPackTemplateV2 booster, Color accent) {
    final tags = booster.tags.take(2).join(', ');
    final reason = tags.isNotEmpty ? 'Review: $tags' : null;
    final reasonColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;
    return Container(
      width: 180,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booster.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          if (reason != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                reason,
                style: TextStyle(fontSize: 12, color: reasonColor),
              ),
            ),
          const Spacer(),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => _start(booster),
              style: ElevatedButton.styleFrom(backgroundColor: accent),
              child: const Text('Start now'),
            ),
          ),
        ],
      ),
    );
  }
}
