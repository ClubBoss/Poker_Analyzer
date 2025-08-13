import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/theory_lesson_node.dart';
import '../models/v2/training_pack_spot.dart';
import '../services/effective_theory_injector_service.dart';
import '../services/training_session_service.dart';

class DecayReviewRecapBanner extends StatefulWidget {
  const DecayReviewRecapBanner({super.key});

  @override
  State<DecayReviewRecapBanner> createState() => _DecayReviewRecapBannerState();
}

class _DecayReviewRecapBannerState extends State<DecayReviewRecapBanner> {
  final _injector = EffectiveTheoryInjectorService();
  final Map<String, List<TheoryLessonNode>> _boosters = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final session = context.read<TrainingSessionService>();
    final tags = <String>{};
    for (final a in session.completedAttempts) {
      final spot = session.spots.firstWhere(
        (s) => s.id == a.spotId,
        orElse: () => TrainingPackSpot(id: ''),
      );
      for (final t in spot.tags) {
        if (!t.startsWith('cat:')) tags.add(t);
      }
    }
    for (final tag in tags) {
      final lessons = await _injector.getInjectableLessonsForTag(tag);
      if (lessons.isNotEmpty) {
        _boosters[tag] = lessons;
      }
    }
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _boosters.isEmpty) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
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
          const Text(
            'Восстановленные навыки',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          for (final entry in _boosters.entries)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              iconColor: accent,
              collapsedIconColor: accent,
              title: Row(
                children: [
                  const Icon(Icons.bolt, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    entry.key,
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              children: [
                for (final lesson in entry.value)
                  Padding(
                    padding: const EdgeInsets.only(left: 24, bottom: 4),
                    child: Text(
                      '• ${lesson.resolvedTitle}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
