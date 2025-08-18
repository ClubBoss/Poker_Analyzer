import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/saved_hand_manager_service.dart';
import '../helpers/category_translations.dart';
import 'corrected_mistake_history_screen.dart';

class CategoryRecoveryScreen extends StatelessWidget {
  const CategoryRecoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final Map<String, double> map = {};
    for (final h in hands) {
      if (!h.corrected) continue;
      final r = h.evLossRecovered;
      if (r == null) continue;
      final cat = h.category ?? '';
      map[cat] = (map[cat] ?? 0) + r;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Scaffold(
      appBar: AppBar(
        title: const Text('История устранённых слабостей'),
        centerTitle: true,
      ),
      body: entries.isEmpty
          ? const Center(
              child: Text(
                'Нет данных',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final e = entries[index];
                final name = translateCategory(e.key).isEmpty
                    ? 'Без категории'
                    : translateCategory(e.key);
                return ListTile(
                  title: Text(
                    name,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    '+${e.value.toStringAsFixed(2)} EV',
                    style: const TextStyle(color: Colors.greenAccent),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CorrectedMistakeHistoryScreen(category: e.key),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
