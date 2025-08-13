import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../services/saved_hand_manager_service.dart';

class EVRecoveryHistoryScreen extends StatelessWidget {
  const EVRecoveryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 13));
    final days = [for (var i = 0; i < 14; i++) start.add(Duration(days: i))];
    final Map<DateTime, double> map = {};
    for (final h in hands) {
      if (!h.corrected) continue;
      final r = h.evLossRecovered;
      if (r == null) continue;
      final d = DateTime(h.savedAt.year, h.savedAt.month, h.savedAt.day);
      if (d.isBefore(start)) continue;
      map[d] = (map[d] ?? 0) + r;
    }
    final locale = Intl.getCurrentLocale();
    return Scaffold(
      appBar: AppBar(
        title: const Text('История восстановления EV'),
        centerTitle: true,
      ),
      body: ListView.separated(
        itemCount: days.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final d = days[days.length - 1 - index];
          final sum = map[d] ?? 0;
          final label = DateFormat('d MMMM', locale).format(d);
          return ListTile(
            title: Text(label, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              '${sum > 0 ? '+' : ''}${sum.toStringAsFixed(2)} EV',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        },
      ),
    );
  }
}
