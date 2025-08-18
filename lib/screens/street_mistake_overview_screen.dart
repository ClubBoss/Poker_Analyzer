import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helpers/poker_street_helper.dart';
import '../services/saved_hand_manager_service.dart';
import 'saved_hands_screen.dart';
import '../widgets/sync_status_widget.dart';

class StreetMistakeOverviewScreen extends StatelessWidget {
  final String dateFilter;
  const StreetMistakeOverviewScreen({super.key, required this.dateFilter});

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final now = DateTime.now();
    final filtered = [
      for (final h in hands)
        if (dateFilter == 'Все' ||
            (dateFilter == 'Сегодня' && _sameDay(h.date, now)) ||
            (dateFilter == '7 дней' &&
                h.date.isAfter(now.subtract(const Duration(days: 7)))) ||
            (dateFilter == '30 дней' &&
                h.date.isAfter(now.subtract(const Duration(days: 30)))))
          h,
    ];
    final counts = {for (final s in kStreetNames) s: 0};
    for (final h in filtered) {
      final exp = h.expectedAction?.trim().toLowerCase();
      final gto = h.gtoAction?.trim().toLowerCase();
      if (exp != null && gto != null && exp != gto) {
        final name = streetName(h.boardStreet);
        counts[name] = counts[name]! + 1;
      }
    }
    final max = counts.values.fold<int>(0, (a, b) => a > b ? a : b);
    final accent = Theme.of(context).colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ошибки по улицам'),
        centerTitle: true,
        actions: [SyncStatusIcon.of(context)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            for (final s in kStreetNames)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SavedHandsScreen(
                        initialAccuracy: 'errors',
                        initialStreet: s,
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          s,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      Expanded(
                        child: Stack(
                          children: [
                            Container(
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: max > 0 ? counts[s]! / max : 0,
                              child: Container(
                                height: 24,
                                decoration: BoxDecoration(
                                  color: accent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Positioned.fill(
                              child: Center(
                                child: Text(
                                  counts[s]!.toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
