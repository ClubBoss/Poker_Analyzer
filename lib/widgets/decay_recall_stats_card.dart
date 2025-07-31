import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/tag_retention_tracker.dart';

/// Small card summarizing how many decayed tags were reinforced during a booster session.
class DecayRecallStatsCard extends StatelessWidget {
  final Map<String, double> tagDeltas;
  final int spotCount;
  const DecayRecallStatsCard({
    super.key,
    required this.tagDeltas,
    required this.spotCount,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: context.read<TagRetentionTracker>().getDecayedTags(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final decayed = snapshot.data!.map((e) => e.toLowerCase()).toSet();
        final refreshed = tagDeltas.keys
            .map((e) => e.toLowerCase())
            .where(decayed.contains)
            .toSet()
            .length;
        if (refreshed == 0) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Text('🔥', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You refreshed $refreshed key topics · $spotCount spots reviewed',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
