import 'package:flutter/material.dart';

import '../services/recommendation_feed_engine.dart';

class FeedRecommendationWidget extends StatelessWidget {
  final List<FeedRecommendationCard> cards;
  final void Function(String packId) onTap;

  const FeedRecommendationWidget({
    super.key,
    required this.cards,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    final accent = Theme.of(context).colorScheme.secondary;
    final display = cards.take(3).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: display.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final c = display[i];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[850],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                c.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (c.subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(c.subtitle, style: const TextStyle(color: Colors.white70)),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => onTap(c.packId),
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  child: Text(c.cta),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
