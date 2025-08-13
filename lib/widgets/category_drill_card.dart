import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
import '../helpers/category_translations.dart';
import '../screens/training_session_screen.dart';
import '../utils/context_extensions.dart';

class CategoryDrillCard extends StatefulWidget {
  const CategoryDrillCard({super.key});

  @override
  State<CategoryDrillCard> createState() => _CategoryDrillCardState();
}

class _CategoryDrillCardState extends State<CategoryDrillCard> {
  static const _key = 'top_mistake_drill_done';
  static const _tsKey = 'category_drill_last_time';
  bool _done = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final done = p.getBool(_key) ?? false;
      final ts = p.getInt(_tsKey);
      final hide = ts != null &&
          DateTime.now()
                  .difference(DateTime.fromMillisecondsSinceEpoch(ts))
                  .inDays <
              7;
      if (mounted) setState(() => _done = done && !hide);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_done) return const SizedBox.shrink();
    final hands = context.watch<SavedHandManagerService>().hands;
    final map = <String, int>{};
    for (final h in hands.reversed.take(20)) {
      final cat = h.category;
      final exp = h.expectedAction;
      final gto = h.gtoAction;
      if (cat == null || cat.isEmpty) continue;
      if (exp == null || gto == null) continue;
      if (exp.trim().toLowerCase() == gto.trim().toLowerCase()) continue;
      map[cat] = (map[cat] ?? 0) + 1;
    }
    if (map.isEmpty) return const SizedBox.shrink();
    final entry = map.entries.reduce((a, b) => a.value >= b.value ? a : b);
    if (entry.value < 3) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    final name = translateCategory(entry.key).isEmpty
        ? 'Без категории'
        : translateCategory(entry.key);
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.flag, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Проработка категории',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(name, style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final tpl = await TrainingPackService.createDrillFromCategory(
                  context, entry.key);
              if (tpl == null) return;
              await context.read<TrainingSessionService>().startSession(tpl);
              final p = await SharedPreferences.getInstance();
              await p.setInt(_tsKey, DateTime.now().millisecondsSinceEpoch);
              if (mounted) setState(() => _done = false);
              await context.ifMounted(() async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TrainingSessionScreen()),
                );
              });
            },
            child: const Text('Тренировать'),
          ),
        ],
      ),
    );
  }
}
