import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/training_session_service.dart';
import '../services/training_pack_service.dart';
import '../helpers/category_translations.dart';
import '../screens/training_session_screen.dart';

class RecentUnlocksBanner extends StatelessWidget {
  const RecentUnlocksBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final entries = <MapEntry<String, double>>[];
    final seen = <String>{};
    for (var i = hands.length - 1; i >= 0; i--) {
      final h = hands[i];
      final cat = h.category;
      final loss = h.evLoss ?? 0;
      if (cat == null || cat.isEmpty || loss <= 0 || h.corrected) continue;
      if (!seen.contains(cat)) {
        entries.add(MapEntry(cat, loss));
        seen.add(cat);
        if (entries.length >= 3) break;
      } else if (entries.any((e) => e.key == cat)) {
        final idx = entries.indexWhere((e) => e.key == cat);
        entries[idx] = MapEntry(cat, entries[idx].value + loss);
      }
    }
    if (entries.isEmpty) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Разблокированные ошибки',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      translateCategory(e.key).isEmpty
                          ? 'Без категории'
                          : translateCategory(e.key),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  Text(
                    '-${e.value.toStringAsFixed(2)} EV',
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final tpl =
                          await TrainingPackService.createDrillFromCategory(
                              context, e.key);
                      if (tpl == null) return;
                      await context
                          .read<TrainingSessionService>()
                          .startSession(tpl);
                      if (context.mounted) {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const TrainingSessionScreen()),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: accent),
                    child: const Text('Тренировать'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
