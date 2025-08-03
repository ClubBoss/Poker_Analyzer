import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/saved_hand_manager_service.dart';
import '../services/training_pack_service.dart';
import '../services/training_session_service.dart';
import '../screens/training_session_screen.dart';
import '../utils/context_extensions.dart';

class TopMistakeDrillCard extends StatefulWidget {
  const TopMistakeDrillCard({super.key});

  @override
  State<TopMistakeDrillCard> createState() => _TopMistakeDrillCardState();
}

class _TopMistakeDrillCardState extends State<TopMistakeDrillCard> {
  static const _key = 'top_mistake_drill_done';
  bool _done = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _done = p.getBool(_key) ?? false);
    });
  }

  Future<void> _mark() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_key, true);
    if (mounted) setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    final hands = context.watch<SavedHandManagerService>().hands;
    final map = <String, double>{};
    for (final h in hands) {
      final cat = h.category;
      final exp = h.expectedAction;
      final gto = h.gtoAction;
      if (cat == null || cat.isEmpty) continue;
      if (exp == null || gto == null) continue;
      if (exp.trim().toLowerCase() == gto.trim().toLowerCase()) continue;
      map[cat] = (map[cat] ?? 0) + (h.evLoss ?? 0);
    }
    if (_done || map.length < 3) return const SizedBox.shrink();
    final accent = Theme.of(context).colorScheme.secondary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.bolt, color: accent),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Топ ошибки',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Восстановите EV',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final tpl = await TrainingPackService.createTopMistakeDrill(context);
              if (tpl == null) return;
              await context.read<TrainingSessionService>().startSession(tpl);
              await _mark();
              await context.ifMounted(() async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TrainingSessionScreen()),
                );
              });
            },
            child: const Text('Начать'),
          ),
        ],
      ),
    );
  }
}
