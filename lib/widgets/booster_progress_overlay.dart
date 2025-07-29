import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/training_session_service.dart';

/// Lightweight HUD displayed during booster drills.
///
/// Shows the focused tag, current progress and a motivational message.
class BoosterProgressOverlay extends StatelessWidget {
  const BoosterProgressOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TrainingSessionService>(
      builder: (context, service, _) {
        final tpl = service.template;
        final isBooster =
            tpl?.meta['type']?.toString().toLowerCase() == 'booster';
        final session = service.session;
        if (!isBooster || session == null || service.isPaused) {
          return const SizedBox.shrink();
        }
        if (session.completedAt != null) return const SizedBox.shrink();

        final spot = service.currentSpot;
        if (spot == null) return const SizedBox.shrink();

        final tags = spot.tags;
        final tag = tags.isNotEmpty
            ? tags.firstWhere(
                (t) => !t.startsWith('cat:'),
                orElse: () => tags.first,
              )
            : '';
        final total = tpl?.spots.length ?? 0;
        final index = session.index;
        final progress = total > 0 ? (index + 1) / total : 0.0;
        final accent = Theme.of(context).colorScheme.secondary;
        final textStyle = const TextStyle(color: Colors.white);
        final motivator =
            progress >= 0.75 ? '💪 Almost there!' : '🔥 Keep going!';

        return Positioned(
          top: 8,
          left: 8,
          right: 8,
          child: SafeArea(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (tag.isNotEmpty)
                    Text('Practicing: $tag', style: textStyle),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.white24,
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${index + 1} / $total • $motivator',
                    style: textStyle.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
