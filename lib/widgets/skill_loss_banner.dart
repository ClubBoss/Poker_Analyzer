import 'package:flutter/material.dart';

import '../services/skill_loss_detector.dart';
import '../screens/tag_insight_screen.dart';

class SkillLossBanner extends StatelessWidget {
  final List<SkillLoss> losses;
  final void Function(String tag) onTapReview;

  const SkillLossBanner({
    super.key,
    required this.losses,
    required this.onTapReview,
  });

  @override
  Widget build(BuildContext context) {
    if (losses.isEmpty) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final display = losses.take(3).toList();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚠️ Skills in Decline',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 4),
          for (final loss in display)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TagInsightScreen(tag: loss.tag),
                        ),
                      ),
                      child: Text(
                        '${loss.tag} - ${loss.trend}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => onTapReview(loss.tag),
                    style: ElevatedButton.styleFrom(backgroundColor: accent),
                    child: const Text('Review'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
