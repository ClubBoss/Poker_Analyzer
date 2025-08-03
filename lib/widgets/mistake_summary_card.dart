import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/poker_street_helper.dart';
import '../services/saved_hand_manager_service.dart';
import '../theme/app_colors.dart';
import '../constants/app_constants.dart';

class MistakeSummaryCard extends StatelessWidget {
  const MistakeSummaryCard({super.key});

  IconData _streetIcon(String street) {
    switch (street) {
      case 'Preflop':
        return Icons.filter_1;
      case 'Flop':
        return Icons.filter_2;
      case 'Turn':
        return Icons.filter_3;
      default:
        return Icons.filter_4;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final streetMap = <String, int>{};
    final posMap = <String, int>{};
    for (final h in hands) {
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (exp != null && gto != null && exp != gto) {
        streetMap.update(streetName(h.boardStreet), (v) => v + 1, ifAbsent: () => 1);
        posMap.update(h.heroPosition, (v) => v + 1, ifAbsent: () => 1);
      }
    }
    final topStreets = streetMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topPositions = posMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Container(
      padding: const EdgeInsets.all(AppConstants.padding16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppConstants.radius8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Топ улиц с ошибками',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final e in topStreets.take(3))
                Chip(
                  backgroundColor: Colors.grey[800],
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_streetIcon(e.key), size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text('${e.key} ${e.value}',
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Топ позиций с ошибками',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final e in topPositions.take(3))
                Chip(
                  backgroundColor: Colors.grey[800],
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event_seat, size: 16, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text('${e.key} ${e.value}',
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
