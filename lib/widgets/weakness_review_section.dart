import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../services/pack_library_loader_service.dart';
import '../services/weakness_review_engine.dart';

class WeaknessReviewSection extends StatelessWidget {
  final List<WeaknessReviewItem> items;
  final void Function(String packId) onTap;

  const WeaknessReviewSection({
    super.key,
    required this.items,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final packs = PackLibraryLoaderService.instance.library;
    final display = items.take(3).toList();
    return ListView.separated(
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: display.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final item = display[i];
        final pack = packs.firstWhereOrNull((p) => p.id == item.packId);
        final title = pack?.name ?? item.packId;
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
                item.tag,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(title, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 4),
              Text(item.reason, style: const TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => onTap(item.packId),
                  style: ElevatedButton.styleFrom(backgroundColor: accent),
                  child: const Text('Review'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
